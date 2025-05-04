#ifndef __FERN_HELPERS__
#define __FERN_HELPERS__

#include "fern.h"

void show_help();
void show_lite_help();
char* str_to_lower(const char *str);
void highlight_text(char *line, const char *query);
char* get_notes_dir(Config *config);
char* get_date_filename(int days_offset);
int ensure_daily_note_exists(Config *config, const char *filename);

#endif
