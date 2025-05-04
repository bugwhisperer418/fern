/*
 * fern - A CLI note-taking tool for daily markdown notes
 */
#include "fern.h"
#include "helpers.h"
#include <dirent.h>
#include <getopt.h>
#include <libgen.h>
#include <pthread.h>
#include <sys/stat.h>

Config *config;

int main(int argc, char *argv[]) {
  char *template_name = NULL;

  // Load config first
  load_config();

  if (argc == 1) {
    show_lite_help();
    return 0;
  }

  // Handle help command early
  if (strcmp(argv[1], "help") == 0 || strcmp(argv[1], "-h") == 0) {
    show_help();
    return 0;
  }

  // Ensure notes directory exists
  char *notes_dir = get_notes_dir(config);
  create_path_if_not_exists(notes_dir);

  if (strcmp(argv[1], "add") == 0) {
    // Check for template option
    int add_optind = 2;
    if (add_optind < argc && strcmp(argv[add_optind], "-t") == 0) {
      if (add_optind + 1 >= argc) {
        fprintf(stderr, "Error: -t option requires a template name\n");
        return 1;
      }
      template_name = argv[add_optind + 1];
      add_optind += 2;
    }

    if (add_optind >= argc) {
      fprintf(stderr, "Error: Please provide note content\n");
      return 1;
    }

    // Check if this is a template-based named note
    if (template_name != NULL) {
      create_note_from_template(argv[add_optind], template_name);
    } else {
      // Regular note addition to daily note
      add_note(config, argv[add_optind]);
    }
  } else if (strcmp(argv[1], "view") == 0) {
    const char *when = (argc > 2) ? argv[2] : "today";
    if (strcmp(when, "today") != 0 && strcmp(when, "yesterday") != 0) {
      fprintf(stderr,
              "Error: view command accepts only 'today' or 'yesterday'\n");
      return 1;
    }
    view_note(config, when);
  } else if (strcmp(argv[1], "search") == 0) {
    if (argc < 3) {
      fprintf(stderr, "Error: Please provide search query\n");
      return 1;
    }
    search_notes(argv[2]);
  } else {
    fprintf(stderr, "Unknown command: %s\n", argv[1]);
    show_help();
    return 1;
  }

  return 0;
}

void load_config() {
  char config_path[MAX_PATH_LEN];
  char *home = getenv("HOME");
  FILE *config_file;
  char line[MAX_LINE_LEN];
  char key[MAX_PATH_LEN];
  char value[MAX_PATH_LEN];

  // Initialize defaults
  strcpy(config->notes_dir, "");
  strcpy(config->editor, "");
  strcpy(config->templates_dir, "");
  strcpy(config->default_template, "");

  // Try to get config file path
  if (home != NULL) {
    snprintf(config_path, MAX_PATH_LEN, "%s/.fernrc", home);
  } else {
    strcpy(config_path, ".fernrc");
  }

  // Try to open config file
  config_file = fopen(config_path, "r");
  if (config_file == NULL) {
    // Config file doesn't exist, create one with defaults
    config_file = fopen(config_path, "w");
    if (config_file != NULL) {
      if (home != NULL) {
        fprintf(config_file, "notes_dir = %s/notes\n", home);
        fprintf(config_file, "templates_dir = %s/notes/templates\n", home);
      } else {
        fprintf(config_file, "notes_dir = ./notes\n");
        fprintf(config_file, "templates_dir = ./notes/templates\n");
      }
      fprintf(config_file, "editor = \n");
      fprintf(config_file, "default_template = default\n");
      fclose(config_file);

      // Reopen for reading
      config_file = fopen(config_path, "r");
    }
  }

  // Read config file
  if (config_file != NULL) {
    while (fgets(line, MAX_LINE_LEN, config_file) != NULL) {
      // Skip comments and empty lines
      if (line[0] == '#' || line[0] == '\n' || line[0] == '\r') {
        continue;
      }

      // Parse key-value pairs
      if (sscanf(line, "%[^ =] = %[^\n]", key, value) == 2) {
        if (strcmp(key, "notes_dir") == 0) {
          strcpy(config->notes_dir, value);
        } else if (strcmp(key, "editor") == 0) {
          strcpy(config->editor, value);
        } else if (strcmp(key, "templates_dir") == 0) {
          strcpy(config->templates_dir, value);
        } else if (strcmp(key, "default_template") == 0) {
          strcpy(config->default_template, value);
        }
      }
    }
    fclose(config_file);
  }

  // Apply environment overrides if they exist
  char *env_notes_dir = getenv("FERN_DIR");
  char *env_editor = getenv("EDITOR");
  char *env_templates_dir = getenv("FERN_TEMPLATES_DIR");

  if (env_notes_dir != NULL) {
    strcpy(config->notes_dir, env_notes_dir);
  }

  if (env_editor != NULL) {
    strcpy(config->editor, env_editor);
  }

  if (env_templates_dir != NULL) {
    strcpy(config->templates_dir, env_templates_dir);
  }

  // Expand ~ to home directory if present at the start of paths
  if (home != NULL) {
    if (config->notes_dir[0] == '~') {
      char temp[MAX_PATH_LEN];
      snprintf(temp, MAX_PATH_LEN, "%s%s", home, config->notes_dir + 1);
      strcpy(config->notes_dir, temp);
    }

    if (config->templates_dir[0] == '~') {
      char temp[MAX_PATH_LEN];
      snprintf(temp, MAX_PATH_LEN, "%s%s", home, config->templates_dir + 1);
      strcpy(config->templates_dir, temp);
    }
  }

  // Ensure templates directory exists
  if (strlen(config->templates_dir) > 0) {
    create_path_if_not_exists(config->templates_dir);

    // Create default template if it doesn't exist
    if (strlen(config->default_template) > 0) {
      char default_template_path[MAX_PATH_LEN];
      snprintf(default_template_path, MAX_PATH_LEN, "%s/%s.md",
               config->templates_dir, config->default_template);

      if (access(default_template_path, F_OK) == -1) {
        FILE *template_file = fopen(default_template_path, "w");
        if (template_file != NULL) {
          fprintf(template_file, "# {{title}}\n\n");
          fprintf(template_file, "Created: {{date}}\n\n");
          fprintf(template_file, "## Notes\n\n");
          fclose(template_file);
        }
      }
    }
  }
}

// Create directory path if it doesn't exist
void create_path_if_not_exists(const char *path) {
  char tmp[MAX_PATH_LEN];
  char *p = NULL;
  size_t len;

  snprintf(tmp, sizeof(tmp), "%s", path);
  len = strlen(tmp);

  // Remove trailing slash
  if (tmp[len - 1] == '/' || tmp[len - 1] == '\\') {
    tmp[len - 1] = 0;
  }

  // Create all directories in path
  for (p = tmp + 1; *p; p++) {
    if (*p == '/' || *p == '\\') {
      *p = 0;
#ifdef _WIN32
      mkdir(tmp);
#else
      mkdir(tmp, 0755);
#endif
      *p = '/';
    }
  }

#ifdef _WIN32
  mkdir(tmp);
#else
  mkdir(tmp, 0755);
#endif
}

// Add a note to today's daily note file
void add_note(Config *config, const char *content) {
  char *filename = get_date_filename(0);
  char filepath[MAX_PATH_LEN];
  FILE *file;
  time_t now = time(NULL);
  struct tm *tm_info = localtime(&now);
  char timestamp[32];

  if (!ensure_daily_note_exists(config, filename)) {
    view_note(config, 0);
    return;
  }

  snprintf(filepath, MAX_PATH_LEN, "%s/%s", get_notes_dir(config), filename);

  file = fopen(filepath, "a");
  if (file == NULL) {
    fprintf(stderr, "Error: Could not open file %s\n", filepath);
    return;
  }

  strftime(timestamp, sizeof(timestamp), "%H:%M", tm_info);
  fprintf(file, "## %s\n\n%s\n\n", timestamp, content);
  fclose(file);

  printf("✓ Note added to %s\n", filename);
}

// View today's or yesterday's note
void view_note(Config *config, const char *when) {
  int days_offset = (strcmp(when, "yesterday") == 0) ? -1 : 0;
  char *filename = get_date_filename(days_offset);
  char filepath[MAX_PATH_LEN];
  char command[MAX_PATH_LEN * 2];

  if (!ensure_daily_note_exists(config, filename)) {
    return;
  }

  snprintf(filepath, MAX_PATH_LEN, "%s/%s", get_notes_dir(config), filename);

  // Try to use config editor first, then environment, then system defaults
  if (strlen(config->editor) > 0) {
    snprintf(command, sizeof(command), "%s %s", config->editor, filepath);
  } else {
    char *editor = getenv("EDITOR");
    if (editor == NULL) {
#ifdef _WIN32
      snprintf(command, sizeof(command), "notepad %s", filepath);
#else
      // Try common editors
      if (access("/usr/bin/vim", X_OK) != -1) {
        editor = "vim";
      } else if (access("/usr/bin/nano", X_OK) != -1) {
        editor = "nano";
      } else if (access("/usr/bin/less", X_OK) != -1) {
        editor = "less";
      } else {
        editor = "cat";
      }
#endif
    }
    snprintf(command, sizeof(command), "%s %s", editor, filepath);
  }
  system(command);
}

// Thread function to search a subset of files
void *search_thread(void *arg) {
  SearchContext *ctx = (SearchContext *)arg;
  char *query_lower = str_to_lower(ctx->query);
  char line[MAX_LINE_LEN];
  char line_lower[MAX_LINE_LEN];
  char result_buffer[MAX_PATH_LEN * 10] = "";
  int result_count = 0;

  // Process files in the assigned range
  for (int i = ctx->start_idx; i < ctx->end_idx; i++) {
    char *filename = ctx->files[i];
    char filepath[MAX_PATH_LEN];
    FILE *file;
    int line_num = 0;
    int matches_in_file = 0;
    char file_matches[MAX_PATH_LEN * 5] = "";

    snprintf(filepath, MAX_PATH_LEN, "%s/%s", get_notes_dir(config), filename);

    file = fopen(filepath, "r");
    if (file == NULL)
      continue;

    // Process each line in the file
    while (fgets(line, MAX_LINE_LEN, file) != NULL) {
      line_num++;
      strcpy(line_lower, str_to_lower(line));

      if (strstr(line_lower, query_lower) != NULL) {
        // First match in this file, add filename header
        if (matches_in_file == 0) {
          char header[MAX_PATH_LEN];
          snprintf(header, MAX_PATH_LEN, "\n\033[1m%s\033[0m\n", filename);
          strcat(file_matches, header);
        }

        // Add the line with line number
        char match_line[MAX_LINE_LEN + 100];
        char line_copy[MAX_LINE_LEN];
        strcpy(line_copy, line);

        // Remove newline
        int len = strlen(line_copy);
        if (len > 0 &&
            (line_copy[len - 1] == '\n' || line_copy[len - 1] == '\r'))
          line_copy[len - 1] = '\0';

        snprintf(match_line, sizeof(match_line), "  Line %d: ", line_num);
        strcat(file_matches, match_line);

        // Add highlighted line
        char highlighted[MAX_LINE_LEN * 2];
        strcpy(highlighted, line_copy);
        highlight_text(highlighted, ctx->query);
        strcat(file_matches, highlighted);
        strcat(file_matches, "\n");

        matches_in_file++;
        result_count++;

        // Prevent buffer overflow
        if (strlen(file_matches) > MAX_PATH_LEN * 4) {
          strcat(file_matches, "  [additional matches truncated...]\n");
          break;
        }
      }
    }

    fclose(file);

    // Add file results to thread results
    if (matches_in_file > 0) {
      strcat(result_buffer, file_matches);
    }

    // Prevent buffer overflow in overall results
    if (strlen(result_buffer) > MAX_PATH_LEN * 9) {
      strcat(result_buffer, "\n[additional matches truncated...]\n");
      break;
    }
  }

  // Copy results to the thread context
  if (result_count > 0) {
    strncpy(ctx->results, result_buffer, MAX_PATH_LEN * 10 - 1);
  } else {
    ctx->results[0] = '\0';
  }

  return NULL;
}

// Search all note files for a query using multithreading
void search_notes(const char *query) {
  DIR *dir;
  struct dirent *entry;
  char **files = NULL;
  int file_count = 0;
  pthread_t threads[MAX_THREAD_COUNT];
  SearchContext contexts[MAX_THREAD_COUNT];
  int i;

  dir = opendir(get_notes_dir(config));
  if (dir == NULL) {
    fprintf(stderr, "Error: Could not open notes directory\n");
    return;
  }

  // Allocate memory for file list
  files = (char **)malloc(MAX_FILE_COUNT * sizeof(char *));
  if (files == NULL) {
    fprintf(stderr, "Error: Memory allocation failed\n");
    closedir(dir);
    return;
  }

  // Collect all markdown files
  while ((entry = readdir(dir)) != NULL && file_count < MAX_FILE_COUNT) {
    if (strstr(entry->d_name, ".md") != NULL) {
      files[file_count] = strdup(entry->d_name);
      file_count++;
    }
  }
  closedir(dir);

  if (file_count == 0) {
    printf("No markdown files found in notes directory\n");
    free(files);
    return;
  }

  // Determine number of threads to use (based on file count and CPU cores)
  int num_threads =
      file_count < MAX_THREAD_COUNT ? file_count : MAX_THREAD_COUNT;
  int files_per_thread = (file_count + num_threads - 1) / num_threads;

  // Create search threads
  for (i = 0; i < num_threads; i++) {
    int start_idx = i * files_per_thread;
    int end_idx = (i + 1) * files_per_thread;
    if (end_idx > file_count)
      end_idx = file_count;

    contexts[i].files = files;
    contexts[i].start_idx = start_idx;
    contexts[i].end_idx = end_idx;
    strcpy(contexts[i].query, query);
    contexts[i].results[0] = '\0';

    pthread_create(&threads[i], NULL, search_thread, &contexts[i]);
  }

  // Wait for all threads to complete
  int total_results = 0;
  printf("\nSearching for '%s'...\n", query);

  for (i = 0; i < num_threads; i++) {
    pthread_join(threads[i], NULL);
    if (strlen(contexts[i].results) > 0) {
      printf("%s", contexts[i].results);
      total_results++;
    }
  }

  // Clean up
  for (i = 0; i < file_count; i++) {
    free(files[i]);
  }
  free(files);

  if (total_results == 0) {
    printf("No results found for '%s'\n", query);
  } else {
    printf("\nSearch complete.\n");
  }
}

void create_note_from_template(const char *note_name,
                               const char *template_name) {
  char template_path[MAX_PATH_LEN];
  char note_path[MAX_PATH_LEN];
  FILE *template_file;
  FILE *note_file;
  char line[MAX_LINE_LEN];
  time_t now = time(NULL);
  struct tm *tm_info = localtime(&now);
  char date_str[64];
  char time_str[64];

  // Format date and time
  strftime(date_str, sizeof(date_str), "%Y-%m-%d", tm_info);
  strftime(time_str, sizeof(time_str), "%H:%M", tm_info);

  // Use default template if none specified
  if (template_name == NULL || strlen(template_name) == 0) {
    template_name = config->default_template;
  }

  // Determine template path
  snprintf(template_path, MAX_PATH_LEN, "%s/%s.md", config->templates_dir,
           template_name);

  // Check if template exists
  if (access(template_path, F_OK) == -1) {
    fprintf(stderr, "Error: Template '%s' not found at %s\n", template_name,
            template_path);
    return;
  }

  // Determine note path (replace spaces with hyphens for filename)
  char safe_note_name[MAX_PATH_LEN];
  strcpy(safe_note_name, note_name);
  for (int i = 0; safe_note_name[i]; i++) {
    if (safe_note_name[i] == ' ') {
      safe_note_name[i] = '-';
    }
  }

  snprintf(note_path, MAX_PATH_LEN, "%s/%s-%s.md", get_notes_dir(config),
           date_str, safe_note_name);

  // Check if note already exists
  if (access(note_path, F_OK) != -1) {
    fprintf(stderr, "Error: Note '%s' already exists\n", note_path);
    return;
  }

  // Open template and create note
  template_file = fopen(template_path, "r");
  if (template_file == NULL) {
    fprintf(stderr, "Error: Could not open template '%s'\n", template_path);
    return;
  }

  note_file = fopen(note_path, "w");
  if (note_file == NULL) {
    fprintf(stderr, "Error: Could not create note '%s'\n", note_path);
    fclose(template_file);
    return;
  }

  // Process template line by line, replacing placeholders
  while (fgets(line, MAX_LINE_LEN, template_file) != NULL) {
    char processed_line[MAX_LINE_LEN * 2];
    strcpy(processed_line, line);

    // Replace {{title}} with note name
    char *title_pos;
    while ((title_pos = strstr(processed_line, "{{title}}")) != NULL) {
      char before[MAX_LINE_LEN];
      char after[MAX_LINE_LEN];

      strncpy(before, processed_line, title_pos - processed_line);
      before[title_pos - processed_line] = '\0';

      strcpy(after, title_pos + 9); // 9 is length of "{{title}}"

      sprintf(processed_line, "%s%s%s", before, note_name, after);
    }

    // Replace {{date}} with current date
    char *date_pos;
    while ((date_pos = strstr(processed_line, "{{date}}")) != NULL) {
      char before[MAX_LINE_LEN];
      char after[MAX_LINE_LEN];

      strncpy(before, processed_line, date_pos - processed_line);
      before[date_pos - processed_line] = '\0';

      strcpy(after, date_pos + 8); // 8 is length of "{{date}}"

      sprintf(processed_line, "%s%s%s", before, date_str, after);
    }

    // Replace {{time}} with current time
    char *time_pos;
    while ((time_pos = strstr(processed_line, "{{time}}")) != NULL) {
      char before[MAX_LINE_LEN];
      char after[MAX_LINE_LEN];

      strncpy(before, processed_line, time_pos - processed_line);
      before[time_pos - processed_line] = '\0';

      strcpy(after, time_pos + 8); // 8 is length of "{{time}}"

      sprintf(processed_line, "%s%s%s", before, time_str, after);
    }

    fprintf(note_file, "%s", processed_line);
  }

  fclose(template_file);
  fclose(note_file);

  printf("✓ Created new note: %s\n", note_path);

  // Open the new note in editor if available
  if (strlen(config->editor) > 0) {
    char command[MAX_PATH_LEN * 2];
    snprintf(command, sizeof(command), "%s %s", config->editor, note_path);
    system(command);
  }
}
