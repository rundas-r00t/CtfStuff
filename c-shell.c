#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <dirent.h>
#include <sys/wait.h>
#include <readline/readline.h>
#include <readline/history.h>

#ifdef _WIN32
#define PATH_SEP ";"
#else
#define PATH_SEP ":"
#endif

#define MAX_TOKENS 256
#define MAX_TOKEN_LEN 999

/* ---- builtin names, used for `type`, `echo`/`exit`/etc., and command
 * tab-completion ---- */
static const char *BUILTINS[] = {"echo", "exit", "type", "pwd", "cd", NULL};

typedef enum {
  TOK_WORD,
  TOK_REDIR_OUT,        /* >  or 1>  */
  TOK_REDIR_OUT_APPEND, /* >> or 1>> */
  TOK_REDIR_ERR,        /* 2>        */
  TOK_REDIR_ERR_APPEND  /* 2>>       */
} token_type;

typedef struct {
  char text[MAX_TOKEN_LEN];
  token_type type;
} token_t;

int find_file(char *arg, char *path_env, int verbose, char *out_path);
static int tokenize(const char *input, token_t tokens[], int max_tokens);
static char **shell_completion(const char *text, int start, int end);

/* -------------------------------------------------------------------------
 * Tokenizer: handles single quotes (fully literal), double quotes
 * (backslash only special before $ ` " \ and newline), backslash escapes
 * outside quotes (next char taken literally), and unquoted redirection
 * operators >, >>, 1>, 1>>, 2>, 2>> (with or without surrounding spaces).
 * ---------------------------------------------------------------------- */
static int tokenize(const char *input, token_t tokens[], int max_tokens) {
  int ntok = 0;
  char buf[MAX_TOKEN_LEN];
  int blen = 0;
  int in_single = 0, in_double = 0;
  const char *p = input;

  buf[0] = '\0';

  while (*p) {
    char c = *p;

    if (in_single) {
      if (c == '\'') {
        in_single = 0;
      } else {
        if (blen < MAX_TOKEN_LEN - 1) buf[blen++] = c;
      }
      p++;
      continue;
    }

    if (in_double) {
      if (c == '"') {
        in_double = 0;
        p++;
      } else if (c == '\\' && (p[1] == '"' || p[1] == '\\' ||
                                p[1] == '$' || p[1] == '`' ||
                                p[1] == '\n')) {
        if (blen < MAX_TOKEN_LEN - 1) buf[blen++] = p[1];
        p += 2;
      } else {
        if (blen < MAX_TOKEN_LEN - 1) buf[blen++] = c;
        p++;
      }
      continue;
    }

    /* unquoted */
    if (c == '\'') {
      in_single = 1;
      p++;
    } else if (c == '"') {
      in_double = 1;
      p++;
    } else if (c == '\\') {
      if (p[1] != '\0') {
        if (blen < MAX_TOKEN_LEN - 1) buf[blen++] = p[1];
        p += 2;
      } else {
        p++; /* trailing backslash, drop it */
      }
    } else if (c == ' ' || c == '\t') {
      if (blen > 0) {
        buf[blen] = '\0';
        if (ntok < max_tokens) {
          strcpy(tokens[ntok].text, buf);
          tokens[ntok].type = TOK_WORD;
          ntok++;
        }
        blen = 0;
      }
      p++;
    } else if (c == '>') {
      /* Decide fd based on trailing digit already collected in buf.
       * "cmd 1>file" -> buf holds "1" at this point (a distinct token
       * from cmd because of the space). "cmd1>file" would incorrectly
       * treat "cmd1" as the fd source; we guard by only special-casing
       * when buf is exactly "1" or "2" or empty. */
      int is_append = (p[1] == '>');
      token_type t;
      if (blen == 1 && buf[0] == '2') {
        t = is_append ? TOK_REDIR_ERR_APPEND : TOK_REDIR_ERR;
        blen = 0; /* discard the fd digit, it's not a real word */
      } else if (blen == 1 && buf[0] == '1') {
        t = is_append ? TOK_REDIR_OUT_APPEND : TOK_REDIR_OUT;
        blen = 0;
      } else {
        /* flush whatever word was being built before the operator */
        if (blen > 0) {
          buf[blen] = '\0';
          if (ntok < max_tokens) {
            strcpy(tokens[ntok].text, buf);
            tokens[ntok].type = TOK_WORD;
            ntok++;
          }
          blen = 0;
        }
        t = is_append ? TOK_REDIR_OUT_APPEND : TOK_REDIR_OUT;
      }
      if (ntok < max_tokens) {
        tokens[ntok].text[0] = '\0';
        tokens[ntok].type = t;
        ntok++;
      }
      p += is_append ? 2 : 1;
    } else {
      if (blen < MAX_TOKEN_LEN - 1) buf[blen++] = c;
      p++;
    }
  }

  if (blen > 0) {
    buf[blen] = '\0';
    if (ntok < max_tokens) {
      strcpy(tokens[ntok].text, buf);
      tokens[ntok].type = TOK_WORD;
      ntok++;
    }
  }

  return ntok;
}

/* -------------------------------------------------------------------------
 * Tab completion
 * ---------------------------------------------------------------------- */

/* Command-name generator: matches builtins and everything executable on
 * PATH. Used only for the first word on the line. */
static char *command_generator(const char *text, int state) {
  static int list_idx, len;
  static char *path_env_copy = NULL;
  static char *dirs[64];
  static int ndirs;
  static int dir_idx;

  if (state == 0) {
    list_idx = 0;
    len = strlen(text);
    dir_idx = 0;
    ndirs = 0;
    if (path_env_copy) {
      free(path_env_copy);
      path_env_copy = NULL;
    }
    char *pe = getenv("PATH");
    if (pe) {
      path_env_copy = strdup(pe);
      char *tok = strtok(path_env_copy, PATH_SEP);
      while (tok && ndirs < 64) {
        dirs[ndirs++] = tok;
        tok = strtok(NULL, PATH_SEP);
      }
    }
  }

  /* 1) builtins */
  while (BUILTINS[list_idx] != NULL) {
    const char *name = BUILTINS[list_idx++];
    if (strncmp(name, text, len) == 0) {
      return strdup(name);
    }
  }

  /* 2) executables on PATH */
  while (dir_idx < ndirs) {
    DIR *d = opendir(dirs[dir_idx]);
    if (!d) {
      dir_idx++;
      continue;
    }
    struct dirent *entry;
    while ((entry = readdir(d)) != NULL) {
      if (strncmp(entry->d_name, text, len) != 0) continue;
      char full[1024];
      snprintf(full, sizeof(full), "%s/%s", dirs[dir_idx], entry->d_name);
      if (access(full, X_OK) == 0) {
        char *result = strdup(entry->d_name);
        closedir(d);
        return result;
      }
    }
    closedir(d);
    dir_idx++;
  }

  return NULL;
}

static char **shell_completion(const char *text, int start, int end) {
  (void)end;
  rl_attempted_completion_over = 1; /* don't fall back to plain filenames
                                        unless we explicitly ask for it */
  if (start == 0) {
    /* first word on the line: complete against builtins + $PATH, else
     * fall back to filename completion (covers running a program by
     * relative/absolute path) */
    char **matches = rl_completion_matches(text, command_generator);
    if (matches) return matches;
    rl_attempted_completion_over = 0;
    return NULL;
  }
  /* any later word: filename completion */
  rl_attempted_completion_over = 0;
  return NULL;
}

/* -------------------------------------------------------------------------
 * main
 * ---------------------------------------------------------------------- */
int main(int argc, char *argv[]) {
  char *path_env;
  char *line;
  token_t tokens[MAX_TOKENS];
  int ntok;

  path_env = getenv("PATH");
  setbuf(stdout, NULL);

  rl_attempted_completion_function = shell_completion;

  while (1) {
    line = readline("$ ");
    if (line == NULL) { /* EOF (Ctrl-D) */
      printf("\n");
      break;
    }
    if (line[0] == '\0') {
      free(line);
      continue;
    }
    add_history(line);

    ntok = tokenize(line, tokens, MAX_TOKENS);
    free(line);
    if (ntok == 0) continue;

    /* Separate argv words from redirection targets */
    char *cmd_argv[MAX_TOKENS];
    int cmd_argc = 0;
    char *out_file = NULL, *err_file = NULL;
    int out_append = 0, err_append = 0;

    for (int i = 0; i < ntok; i++) {
      switch (tokens[i].type) {
        case TOK_WORD:
          cmd_argv[cmd_argc++] = tokens[i].text;
          break;
        case TOK_REDIR_OUT:
        case TOK_REDIR_OUT_APPEND:
          if (i + 1 < ntok && tokens[i + 1].type == TOK_WORD) {
            out_file = tokens[i + 1].text;
            out_append = (tokens[i].type == TOK_REDIR_OUT_APPEND);
            i++; /* consume filename token */
          }
          break;
        case TOK_REDIR_ERR:
        case TOK_REDIR_ERR_APPEND:
          if (i + 1 < ntok && tokens[i + 1].type == TOK_WORD) {
            err_file = tokens[i + 1].text;
            err_append = (tokens[i].type == TOK_REDIR_ERR_APPEND);
            i++;
          }
          break;
      }
    }
    cmd_argv[cmd_argc] = NULL;
    if (cmd_argc == 0) continue;

    /* Apply redirections for this command's duration; restore after. */
    int saved_stdout = -1, saved_stderr = -1;
    if (out_file) {
      saved_stdout = dup(STDOUT_FILENO);
      int flags = O_WRONLY | O_CREAT | (out_append ? O_APPEND : O_TRUNC);
      int fd = open(out_file, flags, 0644);
      if (fd < 0) {
        perror(out_file);
      } else {
        dup2(fd, STDOUT_FILENO);
        close(fd);
      }
    }
    if (err_file) {
      saved_stderr = dup(STDERR_FILENO);
      int flags = O_WRONLY | O_CREAT | (err_append ? O_APPEND : O_TRUNC);
      int fd = open(err_file, flags, 0644);
      if (fd < 0) {
        perror(err_file);
      } else {
        dup2(fd, STDERR_FILENO);
        close(fd);
      }
    }

    char *tok0 = cmd_argv[0];

    if (strcmp(tok0, "exit") == 0) {
      if (saved_stdout != -1) { dup2(saved_stdout, STDOUT_FILENO); close(saved_stdout); }
      if (saved_stderr != -1) { dup2(saved_stderr, STDERR_FILENO); close(saved_stderr); }
      return 0;
    } else if (strcmp(tok0, "type") == 0) {
      char *target = cmd_argc > 1 ? cmd_argv[1] : NULL;
      if (target == NULL) {
        /* no-op */
      } else if (strcmp(target, "echo") == 0 || strcmp(target, "exit") == 0 ||
                 strcmp(target, "type") == 0 || strcmp(target, "pwd") == 0 ||
                 strcmp(target, "cd") == 0) {
        printf("%s is a shell builtin\n", target);
      } else {
        char full[1024];
        if (find_file(target, path_env, 0, full))
          printf("%s is %s\n", target, full);
        else
          printf("%s: not found\n", target);
      }
    } else if (strcmp(tok0, "echo") == 0) {
      for (int i = 1; i < cmd_argc; i++) {
        printf("%s%s", i == 1 ? "" : " ", cmd_argv[i]);
      }
      printf("\n");
    } else if (strcmp(tok0, "pwd") == 0) {
      char *cwd = getcwd(NULL, 0);
      printf("%s\n", cwd);
      free(cwd);
    } else if (strcmp(tok0, "cd") == 0) {
      char *target = cmd_argc > 1 ? cmd_argv[1] : NULL;
      if (target == NULL) {
        target = getenv("HOME");
        if (target == NULL) {
          fprintf(stderr, "cd: HOME not set\n");
          target = NULL;
        }
      } else if (strcmp(target, "~") == 0) {
        target = getenv("HOME");
        if (target == NULL) fprintf(stderr, "cd: HOME not set\n");
      }
      if (target && chdir(target) != 0) {
        fprintf(stderr, "cd: %s: No such file or directory\n", cmd_argv[1]);
      }
    } else {
      char full[1024];
      if (find_file(tok0, path_env, 0, full)) {
        pid_t pid = fork();
        if (pid == 0) {
          execv(full, cmd_argv);
          perror(full);
          _exit(127);
        } else if (pid > 0) {
          int status;
          waitpid(pid, &status, 0);
        }
      } else {
        fprintf(stderr, "%s: command not found\n", tok0);
      }
    }

    if (saved_stdout != -1) {
      fflush(stdout);
      dup2(saved_stdout, STDOUT_FILENO);
      close(saved_stdout);
    }
    if (saved_stderr != -1) {
      fflush(stderr);
      dup2(saved_stderr, STDERR_FILENO);
      close(saved_stderr);
    }
  }
  return 0;
}

int find_file(char *arg, char *path_env, int verbose, char *out_path) {
  if (path_env == NULL) return 0;
  size_t len = strlen(path_env);
  char *penv = malloc(len + 1);
  strcpy(penv, path_env);
  char *path;
  char tmp[1024];
  int found = 0;

  path = strtok(penv, PATH_SEP);
  while (path != NULL && !found) {
    snprintf(tmp, sizeof(tmp), "%s/%s", path, arg);
    if (access(tmp, X_OK) == 0) {
      found = 1;
      break;
    }
    path = strtok(NULL, PATH_SEP);
  }

  if (found && out_path) strcpy(out_path, tmp);
  if (found && verbose) printf("%s is %s\n", arg, tmp);
  else if (!found && verbose) printf("%s: not found\n", arg);

  free(penv);
  return found;
}
