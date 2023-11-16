#include <kernel/io.h>

port_byte_t port_byte_in(port_t port) {
  // "=a" (result) means: put AL register in variable RESULT when
  // "d" (port) means: load EDX with port
  port_byte_t result;
  __asm__("in %%dx, %%al" : "=a" (result) : "d" (port));
  return result;
}
void port_byte_out(port_t port, port_byte_t data) {
  // "a" (data) means: load EAX with data
  // "d" (port) means: load EDX with port
  __asm__("out %%al, %%dx" : : "a" (data), "d" (port));
}
port_word_t port_word_in(port_t port) {
  port_word_t result;
  __asm__("in %%dx, %%ax" : "=a" (result) : "d" (port));
  return result;
}
void port_wort_out(port_t port, port_word_t data) {
  __asm__("out %%ax, %%dx" : : "a" (data), "d" (port));
}
