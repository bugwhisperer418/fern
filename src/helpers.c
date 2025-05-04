#include "helpers.h"
#include "fern.h"
#include <ctype.h>
#include <time.h>

void show_lite_help() {
  printf("fern - a knowledge management system [v%s]\nUsage:\tfern COMMAND "
         "[ACTION [ARGS...]]\n\nfern is a swiss-army knife for your notetaking "
         "and personal knowledge management. Fern is a helpful commandline "
         "tool to manage, curate, and search a vault of your personal "
         "notes.\n\nTo get started with a new Fern Vault, use 'fern vault "
         "create <path_to_vault>'.\nFor a brief list of all commands and their "
         "options, use 'fern help'.\nFor more in-depth documentation and "
         "advanced usage see the fern(1) manpage (\"man fern\") and/or "
         "https://sr.ht/~bugwhisperer/fern/\n",
         FERN_VERSION);
}

void show_help() {
  printf(
      "USAGE:\n  fern COMMAND [ACTION [ARGS...]]\n\nCOMMANDS:\n  "
      "help\t\t\t\t\t\t\tdisplay Fern help\n\n  vault create "
      "<path>\t\t\t\t\tsetup a new Fern Vault\n  vault stat\t\t\t\t\t\tget "
      "stats of Fern Vault\n\n  bookmark list\t\t\t\t\t\tlist out all "
      "Bookmarks\n  bookmark add <note_name>\t\t\t\tadd a note to Bookmarks\n  "
      "bookmark del <note_name>\t\t\t\tremove a note from Bookmarks\n\n  "
      "journal\t\t\t\t\t\topens today's Journal entry\n  journal open "
      "yesterday|today|tomorrow|<YYYY-MM-DD>\topen a Journal entry\n  journal "
      "find <pattern>\t\t\t\tsearch Journals for matching pattern\n\n  note "
      "add <note> [<template>]\t\t\t\tadd a new Note\n  note del "
      "<note>\t\t\t\t\tdelete a Note\n  note open <note>\t\t\t\t\topen a "
      "Note\n  note move <old_note> <new_note>\t\t\tmove/rename a Note\n  note "
      "find <pattern>\t\t\t\t\tsearch Notes for matching pattern\n\n  template "
      "list\t\t\t\t\t\tget list of Template files\n  template add "
      "<template>\t\t\t\tadd a new Template\n  template del "
      "<template>\t\t\t\tdelete a Template\n  template open "
      "<template>\t\t\t\topen a Template\n  template move <old_template> "
      "<new_template>\t\tmove/rename a Template\n\nFor more in-depth "
      "documentation and advanced usage see the fern(1) manpage (\"man fern\") "
      "and/or https://sr.ht/~bugwhisperer/fern/\n");
}

// Convert string to lowercase for case-insensitive search
char *str_to_lower(const char *str) {
  static char lower[MAX_LINE_LEN];
  int i;

  for (i = 0; str[i] && i < MAX_LINE_LEN - 1; i++) {
    lower[i] = tolower(str[i]);
  }
  lower[i] = '\0';

  return lower;
}
// Highlight query text in a string
void highlight_text(char *line, const char *query) {
  char result[MAX_LINE_LEN * 2];
  char *pos;
  char *line_lower = str_to_lower(line);
  char *query_lower = str_to_lower(query);
  int query_len = strlen(query);

  strcpy(result, "");

  char *current = line;
  char *search_start = line_lower;

  while ((pos = strstr(search_start, query_lower)) != NULL) {
    int offset = pos - search_start;
    int prefix_len = current + offset - line;

    // Copy text before match
    char prefix[MAX_LINE_LEN];
    strncpy(prefix, line, prefix_len);
    prefix[prefix_len] = '\0';
    strcat(result, prefix);

    // Copy highlighted match
    char match[MAX_LINE_LEN];
    strncpy(match, current + offset, query_len);
    match[query_len] = '\0';
    strcat(result, "\033[33m");
    strcat(result, match);
    strcat(result, "\033[0m");

    // Move pointers forward
    search_start = pos + query_len;
    current += offset + query_len;
  }

  // Add remainder of string
  strcat(result, current);

  // Copy result back to line
  strcpy(line, result);
}

// Helper function to get notes directory
char *get_notes_dir(Config *config) {
  static char notes_dir[MAX_PATH_LEN];

  // Use config if available
  if (strlen(config->notes_dir) > 0) {
    strcpy(notes_dir, config->notes_dir);
    return notes_dir;
  }

  // Default fallback if no config
  char *home = getenv("HOME");
  if (home == NULL) {
    home = getenv("USERPROFILE"); // Windows alternative
  }

  if (home != NULL) {
    snprintf(notes_dir, MAX_PATH_LEN, "%s/notes", home);
  } else {
    // Fallback to current directory if HOME not found
    strcpy(notes_dir, "./notes");
  }

  return notes_dir;
}

// Ensure daily note exists and return its path
int ensure_daily_note_exists(Config *config, const char *filename) {
  char filepath[MAX_PATH_LEN];
  FILE *file;
  time_t now = time(NULL);
  struct tm *tm_info = localtime(&now);

  snprintf(filepath, MAX_PATH_LEN, "%s/%s", get_notes_dir(config), filename);

  // Check if file exists
  if (access(filepath, F_OK) != -1) {
    return 1; // File exists
  }

  // Create file with header
  file = fopen(filepath, "w");
  if (file == NULL) {
    fprintf(stderr, "Error: Could not create file %s\n", filepath);
    return 0;
  }

  // Extract date from filename (YYYY-MM-DD)
  int year, month, day;
  sscanf(filename, "%d-%d-%d", &year, &month, &day);

  // Set tm structure to create formatted header
  tm_info->tm_year = year - 1900;
  tm_info->tm_mon = month - 1;
  tm_info->tm_mday = day;

  // Create header with full date format
  char date_str[64];
  strftime(date_str, sizeof(date_str), "%A, %B %d, %Y", tm_info);

  fprintf(file, "# Daily Notes - %s\n\n", date_str);
  fclose(file);

  return 1;
}
