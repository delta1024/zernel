#ifndef __KERNEL_IO_H__
#define __KERNEL_IO_H__

typedef unsigned char port_byte_t;
typedef unsigned short port_t;
typedef unsigned short port_word_t;

port_byte_t port_byte_in(port_t port);
void port_byte_out(port_t port, port_byte_t data);
port_word_t port_word_in(port_t port);
void port_wort_out(port_t port, port_word_t data);

#endif // __KERNEL_IO_H__
