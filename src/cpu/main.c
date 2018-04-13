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
#include"waveforms.h"

typedef int bool;
#define true 1
#define false 0

int open_physical(int);
int unmap_physical(void *, unsigned int);
void * map_physical(int, unsigned int, unsigned int);
unsigned int sevenSegmentHandler(unsigned int);

void main(){
  const char *device = "/dev/input/event0";
  struct input_event event;
  
  bool stopSignal = false;
  bool ctrl = false;
  
  unsigned int key = -1;
  
  volatile int * LEDR_ptr;   //virtualpointer to DE1
  
  int input_fd;
  int output_fd = -1; 
  
  void *LW_virtual;         //physical addresses for light-weight bridge
  
  input_fd = open(device, (O_RDONLY));
  
  if(input_fd < 0){
    fprintf(stderr, "Cannot open %s: %s.\n", device, strerror(errno));
    exit(0);
  }
  
  //Create virtual memory access to the FPGA light-weight bridge
  if((output_fd = open_physical(output_fd))==-1){
    printf("cannot establish physical memory access");
    fflush(stdout); 
    exit(0);
  }
  if((LW_virtual = map_physical(output_fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)) == NULL){
    printf("cannot establish light weight bridge");
    fflush(stdout); 
    exit(0);
  }
  
  //Set virtual address pointer to I/O port
  LEDR_ptr = (unsigned int *) (LW_virtual + LEDR_BASE);
  *LEDR_ptr = 0;
  
  while (!stopSignal){
    while(read(input_fd, &event, sizeof(struct input_event)) > 0){
      
      #define EV_MAKE   1  // when key pressed
      #define EV_BREAK  0  // when key released
      
      //when key is pressed
      if (event.value == EV_MAKE) {
        //check if key code is not zero
        if(event.code != 0){
            //check for stop signal CTRL+X and change stopSignal to true to step out of while loop
            if(event.code == KEY_X && ctrl == 1)
                stopSignal = true;
            //check if key code is CTRL
            if(event.code == KEY_LEFTCTRL || event.code == KEY_RIGHTCTRL)
                ctrl = true;
            //Add key code value to LEDR_BASE port
            *LEDR_ptr += event.code;
        }
      }
      
      if (event.value == EV_BREAK) {
        if(event.code != 0){
            if(event.code == KEY_LEFTCTRL || event.code == KEY_RIGHTCTRL)
                ctrl = false;
            //Subtract key code value from LEDR_BASE port
            *LEDR_ptr -= event.code;
        }
      }
    }
  }
  *LEDR_ptr = 0;
  unmap_physical(LW_virtual, LW_BRIDGE_SPAN);
  close(output_fd);
  close(input_fd);
}

/* Open /dev/mem to give access to physical addresses */
int open_physical (int fd){
    if (fd == -1) // check if already open
        if ((fd = open( "/dev/mem", (O_RDWR | O_SYNC))) == -1){
            printf ("ERROR: could not open \"/dev/mem\"...\n");
            return (-1);
        }
    return fd;
}

/*
* Establish a virtual address mapping for the physical addresses starting
* at base, and extending by span bytes */
void* map_physical(int fd, unsigned int base, unsigned int span){
    void *virtual_base;

    // Get a mapping from physical addresses to virtual addresses
    virtual_base = mmap (NULL, span, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, base);
    if (virtual_base == MAP_FAILED){
        printf ("ERROR: mmap() failed...\n");
        close (fd);
        return (NULL);
    }
    return virtual_base;
}

/* Close the previously-opened virtual address mapping */
int unmap_physical(void * virtual_base, unsigned int span){
    if (munmap (virtual_base, span) != 0){
        printf ("ERROR: munmap() failed...\n");
        return (-1);
    }
    return 0;
}

unsigned int sevenSegmentHandler(unsigned int value){
    unsigned int table[] = {63, 6, 91, 79, 102, 109, 125, 7, 127, 103};
    unsigned int temp;
    if(value<10)
       return table[value];
    else if(value<100){
        temp = table[value-(value/10)];
        temp >> 7;// >> table[value/10];
        
    }
}
