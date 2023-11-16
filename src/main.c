#include <drivers/vga.h>

void kmain() {
  terminal_initialize();
  terminal_write_string("Hello, kernel World\n");
}
