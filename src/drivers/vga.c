#include <drivers/vga.h>

void print_x() {
    unsigned char* buffer = (unsigned char*)0xb8000;
    *buffer = 'X';
}
