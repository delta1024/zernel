#ifndef __DRIVIRS_VGA_H__
#define __DRIVIRS_VGA_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGH = 25;
enum vga_color {
  VGA_COLOR_BLACK = 0,
  VGA_COLOR_BLUE = 1,
  VGA_COLOR_GREEN = 2,
  VGA_COLOR_CYAN = 3,
  VGA_COLOR_RED = 4,
  VGA_COLOR_MAGENTA = 5,
  VGA_COLOR_BROWN = 6,
  VGA_COLOR_LIGHT_GREY = 7, 
  VGA_COLOR_DARK_GREY = 8,
  VGA_COLOR_LIGHT_BLUE = 9,
  VGA_COLOR_LIGHT_GREEN = 10,
  VGA_COLOR_LIGHT_CYAN = 11,
  VGA_COLOR_LIGHT_RED = 12,
  VGA_COLOR_LIGHT_MAGENTA = 13,
  VGA_COLOR_LIGHT_BROWN = 14,
  VGA_COLOR_WHITE = 15,
};
typedef uint8_t vga_color_t;
typedef uint16_t vga_entry_t;
typedef int vga_cursor_t;
typedef struct {
  size_t column;
  size_t row;
  vga_color_t color;
  vga_entry_t* buffer;
} vga_terminal_t;
#define VGA_ENTRY_COLOR(fg, bg) ((fg) | (bg) << 4)
#define VGA_ENTRY(uc, color) ((uint16_t)(uc) | (uint16_t) (color) << 8)

size_t strlen(const char* str);

void terminal_initialize(vga_terminal_t* terminal);

void terminal_put_entry_at(vga_terminal_t* terminal,char c);
void terminal_put_char(vga_terminal_t* terminal,char c);
void terminal_write(vga_terminal_t* terminal,const char* data, size_t size);
void terminal_write_string(vga_terminal_t* terminal,const char* data);
void terminal_clear(vga_terminal_t* terminal);
/** moves the terminal position and cursor to a new line */
void terminal_write_nl(vga_terminal_t* terminal);
vga_cursor_t terminal_get_offset(vga_terminal_t* terminal);
/** sets the cursor position.
 * arguments:
  - offset: int, the offset of the cursor in bytes.
 */
void set_cursor(vga_cursor_t offset);
/**
returns the number of bytes written not the number of characters.
if you are interfacing with video memory with a size greater than uint8_t
you need to devide the result by 2.
*/
vga_cursor_t get_cursor();


#endif // __DRIVIRS_IO_H__
