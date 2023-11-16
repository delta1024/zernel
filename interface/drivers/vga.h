#ifndef __DRIVIRS_VGA_H__
#define __DRIVIRS_VGA_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGTH = 25;
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

#define VGA_ENTRY_COLOR(fg, bg) ((fg) | (bg) << 4)
#define VGA_ENTRY(uc, color) ((uint16_t)(uc) | (uint16_t) (color) << 8)

size_t strlen(const char* str);

void terminal_initialize();
void terminal_set_color(uint8_t color);
void terminal_put_entry_at(char c, uint8_t color, int offset);
void terminal_put_char(char c);
void terminal_write(const char* data, size_t size);
void terminal_write_string(const char* data);
/** moves the terminal position and cursor to a new line */
void terminal_write_nl();
/** sets the cursor position.
 * arguments:
  - offset: int, the offset of the cursor in bytes.
 */
void set_cursor(int offset);
/**
returns the number of bytes written not the number of characters.
if you are interfacing with video memory with a size greater than uint8_t
you need to devide the result by 2.
*/
int get_cursor();


#endif // __DRIVIRS_IO_H__
