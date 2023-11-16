#include <drivers/vga.h>

void kmain() {
  vga_terminal_t terminal;
  terminal_initialize(&terminal);
  terminal_write_string(&terminal, "Hello, kernel World!\n");
}
