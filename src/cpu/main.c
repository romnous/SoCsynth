/* 
 * @file   main.c
 * @desc   Contains an implementation for a simple sine-wave synthesizer for a DE1-SoC.
 * @author Seif Megahed and Rimon Oz
 */
//// includes
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

//// program parameters
#define float2fix30(a) ((int)((a)*1073741824)) // 2^30
#define PI                 3.14159265
#define SAMPLE_RATE        50000
#define AMPLITUDE          1

static char led_digits[] =
        {0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67};

//// global parameters
volatile int buttonsPressed = 0;
volatile int buttonCodes[6] = {0};
volatile int t = 1;

//// addresses to peripherals on the FPGA, which are accessible through the HPS
volatile int *FPGA_OUT;
volatile int *DAC_ptr;
volatile int *LEDR_ptr;
volatile void *LW_virtual;
volatile int *SSEG1_ptr;
volatile int *SSEG2_ptr;

/**
 * Initializes the seven-segment display.
 */
void initialize_number_display() {
    SSEG1_ptr = (unsigned int *) (LW_virtual + HEX3_HEX0_BASE);
    SSEG2_ptr = (unsigned int *) (LW_virtual + HEX5_HEX4_BASE);
}

/**
 * Initializes the DAC.
 */
void initialize_dac() {
    DAC_ptr = (unsigned int *) (LW_virtual + AUDIO_BASE);
}

/**
 * Opens the virtual memory (at `/dev/mem`) through which the physical HPS is accessible.
 * @param fileDescriptor The file descriptor of the virtual memory (at `/dev/mem`).
 * @return               The new file desecriptor after opening the virtual memory.
 */
int open_physical_memory(int fileDescriptor) {
    if (fileDescriptor == -1) // check if already open
        if ((fileDescriptor = open("/dev/mem", (O_RDWR | O_SYNC))) == -1) {
            printf("ERROR: could not open \"/dev/mem\"...\n");
            return (-1);
        }
    return fileDescriptor;
}

/**
 * Establishes the virtual address mapping for the physical addresses, starting at
 * the specified base, and incrementing by the supplied span width.
 * @param fileDescriptor The file descriptor of the virtual memory.
 * @param base           The base address, at which to start mapping memory.
 * @param span           The span of a single memory address.
 * @return
 */
void *map_physical_memory(int fileDescriptor, unsigned int base, unsigned int span) {
    void *virtualBase;

    // Get a mapping from physical addresses to virtual addresses
    virtualBase = mmap(NULL, span, (PROT_READ | PROT_WRITE), MAP_SHARED, fileDescriptor, base);
    if (virtualBase == MAP_FAILED) {
        printf("ERROR: mmap() failed...\n");
        close(fileDescriptor);
        return (NULL);
    }
    return virtualBase;
}

/**
 * Closes the previously opened virtual address mapping, starting at the specified base, and incrementing by
 * the supplied span width.
 * @param virtualBase The base address, at which to start unmapping.
 * @param span        The span width of a single memory address.
 * @return
 */
int unmap_physical_memory(void *virtualBase, unsigned int span) {
    if (munmap(virtualBase, span) != 0) {
        printf("ERROR: munmap() failed...\n");
        return (-1);
    }
    return 0;
}

/**
 * Writes the specified value to the seven-segment display.
 * @param value The value to display.
 */
void write_number_to_display(int value) {
    unsigned char c[6];
    int i;

    for (i = 0; i < 6; ++i) {
        int digit = value % 10;
        value = value / 10;
        c[i] = led_digits[digit];
    }

    *SSEG1_ptr =
            (unsigned int) (c[3] << 24)
            | (unsigned int) (c[2] << 16)
            | (unsigned int) (c[1] << 8)
            | (unsigned int) c[0];

    *SSEG2_ptr =
            (unsigned int) (c[5] << 8)
            | (unsigned int) c[4];
}

/**
 * Computes the frequency for the specified note, relatively to middle C (n = -9, f = 261.63Hz).
 * @param noteNumber The number corresponding to the note, where, for middle C, n = 9.
 * @return           The frequency for the specified note in Hz.
 */
double compute_frequency(int noteNumber) {
    //middle C is n = -9 or 261.63Hz
    noteNumber -= 28;
    if (noteNumber < 28) {
        double frequency = (440 * pow(2, noteNumber / 12.0));
        return frequency;
    } else
        return 0;
}

/**
 * Mixes up to 6 different notes and writes them to audio. Called as a timer interrupt.
 * @param sig
 * @param si
 * @param uc
 */
static void write_to_audio(int sig, siginfo_t *si, void *uc) {
    while (((*(DAC_ptr+1)>>24)& 0xff) > 1 && buttonCodes[0] != 0) {
        double frequency = compute_frequency(buttonCodes[0]);
        double something = (2 * PI * frequency * t) / SAMPLE_RATE;
        double audio = float2fix30(AMPLITUDE * sin(something));
        *(DAC_ptr+2) = audio;
        *(DAC_ptr+3) = audio;
        t++;
    }
}

/**
 * Initializes a timer which calls {@see write_to_audio}.
 */
void initialize_timer() {
    timer_t timerid;
    struct sigevent sev;
    struct itimerspec its;
    sigset_t mask;
    struct sigaction sa;

    long long frequencyNs = pow(10, 9) / SAMPLE_RATE;

    // Establish handler for timer signal 
    printf("Establishing handler for signal %d\n", SIGRTMIN);
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = write_to_audio;
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIGRTMIN, &sa, NULL) == -1) {
        perror("sigaction");
        exit(EXIT_FAILURE);
    }

    // Block timer signal temporarily 
    printf("Blocking signal %d\n", SIGRTMIN);
    sigemptyset(&mask);
    sigaddset(&mask, SIGRTMIN);
    if (sigprocmask(SIG_SETMASK, &mask, NULL) == -1) {
        perror("sigprocmask");
        exit(EXIT_FAILURE);
    }
    // Create the timer
    sev.sigev_notify = SIGEV_SIGNAL;
    sev.sigev_signo = SIGRTMIN;
    sev.sigev_value.sival_ptr = &timerid;
    if (timer_create(CLOCK_REALTIME, &sev, &timerid) == -1) {
        perror("timer_create");
        exit(EXIT_FAILURE);
    }
    // Start the timer 
    its.it_value.tv_sec = 0;
    its.it_value.tv_nsec = frequencyNs % 1000000000;
    its.it_interval.tv_sec = its.it_value.tv_sec;
    its.it_interval.tv_nsec = its.it_value.tv_nsec;

    if (timer_settime(timerid, 0, &its, NULL) == -1) {
        perror("timer_settime");
        exit(EXIT_FAILURE);
    }
    if (sigprocmask(SIG_UNBLOCK, &mask, NULL) == -1) {
        perror("sigprocmask");
        exit(EXIT_FAILURE);
    }
    fflush(stdout);
}

/**
 * The entry-point of the program.
 */
void main() {
    const char *keyboard = "/dev/input/event0";
    struct input_event event;
    int ctrl = 0;
    unsigned int key = -1;
    int input_fileDescriptor;
    int output_fileDescriptor = -1;
    int pressIgnore = 0;

    input_fileDescriptor = open(keyboard, (O_RDONLY));
    if (input_fileDescriptor < 0) {
        fprintf(stderr, "Cannot open %s: %s.\n", keyboard, strerror(errno));
        exit(0);
    }

    //Create virtual memory access to the FPGA light-weight bridge
    if ((output_fileDescriptor = open_physical_memory(output_fileDescriptor)) == -1) {
        printf("cannot establish physical memory access");
        fflush(stdout);
        exit(0);
    }
    if ((LW_virtual = map_physical_memory(output_fileDescriptor, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)) == NULL) {
        printf("cannot establish light weight bridge");
        fflush(stdout);
        exit(0);
    }
    if ((FPGA_OUT = map_physical_memory(output_fileDescriptor, FPGA_ONCHIP_BASE, FPGA_ONCHIP_SPAN)) == NULL) {
        printf("cannot establish FPGA ONCHIP BASE");
        fflush(stdout);
        exit(0);
    }

    *FPGA_OUT = 0;

    initialize_number_display();
    write_number_to_display(0);
    initialize_dac();
    initialize_timer();

    while (1) {
        while (read(input_fileDescriptor, &event, sizeof(struct input_event)) > 0) {
            //Key press handler
            if (event.value == 1 && event.code != 0) {
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
            }
            //Key release handler
            if (event.value == 0 && event.code != 0) {
                int x = 0;
                int carryOn = 0;
                for (x = 0; x < 6; x++) {
                    if (buttonCodes[x] == event.code || carryOn == 1) {
                        if (x < 5)
                            buttonCodes[x] = buttonCodes[x + 1];
                        else
                            buttonCodes[x] = 0;
                        carryOn = 1;
                    }
                }

                for (x = 5; x > -1; x--) {
                    if (buttonCodes[x] == buttonCodes[x - 1]) {
                        buttonCodes[x] = 0;
                    }
                }
                --buttonsPressed;
            }
            fflush(stdout);
            if (buttonsPressed > 0)
                write_number_to_display(compute_frequency(buttonCodes[0]));
            else
                write_number_to_display(0);
        }
    }
    unmap_physical_memory(LW_virtual, LW_BRIDGE_SPAN);
    close(output_fileDescriptor);
    close(input_fileDescriptor);
}
