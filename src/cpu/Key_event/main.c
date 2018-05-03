/* 
 * File:   main.c
 * Author: seif.megahed
 *
 * Created on April 12, 2018, 10:15 AM
 */

#include<string.h>
#include<stdlib.h>
#include<stdio.h>
#include<fcntl.h>
#include<sys/mman.h>
#include"address_map_arm.h"
#include<linux/input.h>
#include<errno.h>
#include<signal.h>
#include<time.h>
#include<math.h>


typedef int bool;
#define true 1
#define false 0

//#define debug

#define CLOCKID CLOCK_REALTIME
#define SIG SIGRTMIN

#define errExit(msg)    do { perror(msg); exit(EXIT_FAILURE); \
                          } while (0)
#define PI 3.14159265

#define sampleRate 8000
#define amplitude  100


typedef unsigned int u32;



volatile int kamansh = 1;
volatile int buttonsPressed = 0;
volatile int buttonCodes[6] = {0};

int open_physical(int);
int unmap_physical(void *, unsigned int);
void * map_physical(int, unsigned int, unsigned int);
void sevenSegmentHandler(int);



volatile void *LW_virtual;

double getFreq(int n) {
    //middle C is n = -9 or 261.63Hz
    n -= 28;
    if (n < 28) {
        double frequancy = (440*pow(2, n/12.0));
        return frequancy;
    } else
        return 0;
}


volatile int * SSEG1_ptr;
volatile int * SSEG2_ptr;

void sevenSegmentInit() {
    SSEG1_ptr = (unsigned int *) (LW_virtual + HEX3_HEX0_BASE);
    SSEG2_ptr = (unsigned int *) (LW_virtual + HEX5_HEX4_BASE);
}

volatile int * FPGAOUT_ptr;

void fpgaOutInit() {
    FPGAOUT_ptr = (unsigned int *) (LW_virtual + FPGA_ONCHIP_BASE);
}

volatile int * DAC_ptr;

void dacInit() {
    DAC_ptr = (unsigned int *) (LW_virtual + AUDIO_BASE);
}

volatile int t = 1;
double audio;

static void
handler(int sig, siginfo_t *si, void *uc) {
    int x;
    double frequancy;

    audio = 0;
    if (buttonsPressed > 0) {
        for (x = 0; x < 6; x++) {
            if(buttonCodes[x] > 0){
                frequancy = getFreq(buttonCodes[x]);
                double something = (2 * PI * frequancy * t) / sampleRate;
                audio += -amplitude * sin(something);
            }
        }
        audio = audio / buttonsPressed;
    }
    ++t;

#ifdef debug
    printf("%f\n", audio);
#endif
    *FPGAOUT_ptr = audio;
}

void timerInit() {

    long long freq_nanosecs = pow(10, 9) / sampleRate;

    timer_t timerid;
    struct sigevent sev;
    struct itimerspec its;
    sigset_t mask;
    struct sigaction sa;

    // Establish handler for timer signal 
    printf("Establishing handler for signal %d\n", SIG);
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = handler;
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIG, &sa, NULL) == -1)
        errExit("sigaction");

    // Block timer signal temporarily 
#ifdef debug
    printf("Blocking signal %d\n", SIG);
#endif
    sigemptyset(&mask);
    sigaddset(&mask, SIG);
    if (sigprocmask(SIG_SETMASK, &mask, NULL) == -1)
        errExit("sigprocmask");

    // Create the timer
    sev.sigev_notify = SIGEV_SIGNAL;
    sev.sigev_signo = SIG;
    sev.sigev_value.sival_ptr = &timerid;
    if (timer_create(CLOCKID, &sev, &timerid) == -1)
        errExit("timer_create");

    // Start the timer 
    its.it_value.tv_sec = 0;
    its.it_value.tv_nsec = freq_nanosecs % 1000000000;
    its.it_interval.tv_sec = its.it_value.tv_sec;
    its.it_interval.tv_nsec = its.it_value.tv_nsec;

    if (timer_settime(timerid, 0, &its, NULL) == -1)
        errExit("timer_settime");

    if (sigprocmask(SIG_UNBLOCK, &mask, NULL) == -1)
        errExit("sigprocmask");

    fflush(stdout);
}

void main() {

    const char *keyboard = "/dev/input/event0";
    struct input_event event;


    bool stopSignal = false;
    bool ctrl = false;

    unsigned int key = -1;

    //virtual pointer to DE1
    volatile int * LEDR_ptr;

    int input_fd;
    int output_fd = -1;

    //physical addresses for light-weight bridge


    timerInit();

    input_fd = open(keyboard, (O_RDONLY));
    if (input_fd < 0) {
        fprintf(stderr, "Cannot open %s: %s.\n", keyboard, strerror(errno));
        exit(0);
    }

    //Create virtual memory access to the FPGA light-weight bridge
    if ((output_fd = open_physical(output_fd)) == -1) {
        printf("cannot establish physical memory access");
        fflush(stdout);
        exit(0);
    }
    if ((LW_virtual = map_physical(output_fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)) == NULL) {
        printf("cannot establish light weight bridge");
        fflush(stdout);
        exit(0);
    }

    //Set virtual address pointer to I/O port
    LEDR_ptr = (unsigned int *) (LW_virtual + LEDR_BASE);
    *LEDR_ptr = 0;

    fpgaOutInit();
    *FPGAOUT_ptr = 0;
            
    sevenSegmentInit();
    sevenSegmentHandler(0);

    int pressIgnore = 0;

    while (!stopSignal) {
        while (read(input_fd, &event, sizeof (struct input_event)) > 0) {

#define EV_MAKE   1  // when key pressed
#define EV_BREAK  0  // when key released

            //Key press handler
            if (event.value == EV_MAKE) {
                //check if key code is not zero
                if (event.code != 0) {
                    if (event.code == KEY_X)
                        exit(0);
                    int x = 0;
                    for (x = 0; x < 6; x++) {
                        if (buttonCodes[x] == 0) {
                            buttonCodes[x] = event.code;
                            x = 6;
                        }
                    }
                    ++buttonsPressed;
                    //                    printf("\t Number of buttons pressed: %d. %02d %02d %02d %02d %02d %02d\r", ++buttonsPressed, buttonCodes[0], buttonCodes[1], buttonCodes[2], buttonCodes[3], buttonCodes[4], buttonCodes[5]);
                }
            }
            //Key release handler
            if (event.value == EV_BREAK) {
                if (event.code != 0) {
                    int x = 0;
                    bool carryOn = false;
                    for (x = 0; x < 6; x++) {
                        if (buttonCodes[x] == event.code || carryOn) {
                            if (x < 5)
                                buttonCodes[x] = buttonCodes[x + 1];
                            else
                                buttonCodes[x] = 0;
                            carryOn = true;
                        }
                    }

                    for (x = 5; x > -1; x--) {
                        if (buttonCodes[x] == buttonCodes[x - 1]) {
                            buttonCodes[x] = 0;
                        }
                    }
                    --buttonsPressed;
                    //                    printf("\t Number of buttons pressed: %d. %02d %02d %02d %02d %02d %02d\r", --buttonsPressed, buttonCodes[0], buttonCodes[1], buttonCodes[2], buttonCodes[3], buttonCodes[4], buttonCodes[5]);
                }
            }
            fflush(stdout);
            if(buttonsPressed>0)
                sevenSegmentHandler(getFreq(buttonCodes[0]));
            else
                sevenSegmentHandler(0);
        }
    }
    *LEDR_ptr = 0;
    unmap_physical(LW_virtual, LW_BRIDGE_SPAN);
    close(output_fd);
    close(input_fd);
}

/* Open /dev/mem to give access to physical addresses */
int open_physical(int fd) {
    if (fd == -1) // check if already open
        if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1) {
            printf("ERROR: could not open \"/dev/mem\"...\n");
            return (-1);
        }
    return fd;
}

/*
 * Establish a virtual address mapping for the physical addresses starting
 * at base, and extending by span bytes */
void* map_physical(int fd, unsigned int base, unsigned int span) {
    void *virtual_base;

    // Get a mapping from physical addresses to virtual addresses
    virtual_base = mmap(NULL, span, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, base);
    if (virtual_base == MAP_FAILED) {
        printf("ERROR: mmap() failed...\n");
        close(fd);
        return (NULL);
    }
    return virtual_base;
}

/* Close the previously-opened virtual address mapping */
int unmap_physical(void * virtual_base, unsigned int span) {
    if (munmap(virtual_base, span) != 0) {
        printf("ERROR: munmap() failed...\n");
        return (-1);
    }
    return 0;
}

static char led_digits[] = {0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67};

void sevenSegmentHandler(int x) {
    unsigned char c[6];
    int i;

    for (i = 0; i < 6; ++i) {
        int digit = x % 10;
        x = x / 10;
        c[i] = led_digits[digit];
    }

    *SSEG1_ptr = (u32) (c[3] << 24) | (u32) (c[2] << 16) | (u32) (c[1] << 8) | (u32) c[0];
    *SSEG2_ptr = (u32) (c[5] << 8) | (u32) c[4];
}

