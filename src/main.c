#include <drivers/vga.h>
vga_terminal_t terminal;
void kmain() {
  
  terminal_initialize(&terminal);
  terminal_write_string(&terminal, "Hello, kernel World!\nHow are you?");
  terminal_scroll(&terminal);
}
