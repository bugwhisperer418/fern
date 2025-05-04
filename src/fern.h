#ifndef __FERN__
#define __FERN__

#define _POSIX_C_SOURCE 200809L
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define FERN_VERSION "0.0.9"
#define MAX_PATH_LEN 1024
#define MAX_LINE_LEN 4096
#define MAX_FILE_COUNT 10000
#define MAX_THREAD_COUNT 8

typedef struct {
    char notes_dir[MAX_PATH_LEN];
    char editor[MAX_PATH_LEN];
    char templates_dir[MAX_PATH_LEN];
    char default_template[MAX_PATH_LEN];
} Config;

typedef struct {
    char query[256];
    char **files;
    int start_idx;
    int end_idx;
    char results[MAX_PATH_LEN * 10];
} SearchContext;

void load_config();
void add_note(Config *config, const char *content);
void view_note(Config *config, const char *when);
void search_notes(const char *query);
void* search_thread(void *arg);
void create_path_if_not_exists(const char *path);
void create_note_from_template(const char *note_name, const char *template_name);

#endif
