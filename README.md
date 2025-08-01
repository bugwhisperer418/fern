```
⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠘⠳⠀⠀⠙⣠⠖⢀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠙⠛⠣⠈⢦⠈⢴⡿⠃⣀⡔⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠐⠺⠿⠿⠆⠘⣧⡈⢀⣾⠏⣠⣴⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠤⢶⣶⠶⠆⠘⣷⡄⠁⣾⡿⠃⣠⣴⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⣠⣤⣤⣤⣄⠘⣿⣆⠈⢠⣾⠿⢁⣴⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢀⣠⣤⣤⣶⣦⡈⢿⣧⡈⠁⣴⣿⠟⠁⣠⣶⠃⠀⢀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⢉⣉⣩⣤⣤⡄⢻⣿⣄⠘⠁⢠⣾⡿⠁⣠⣾⡟⠀⢀⣠⠀⠀⠀⠀
⠀⠀⠀⠀⠚⠻⠿⠟⠛⠛⠁⠀⠙⣿⣷⡄⠙⠋⣠⣾⣿⠏⢀⣴⣿⠃⢀⣤⠂⠀
⠀⠀⠀⠀⠀⣠⣤⣶⣶⣿⠿⠟⠂⠈⠻⣿⣦⡀⠻⠟⢁⣴⣿⡟⢁⣴⣿⡏⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣶⣶⡄⠙⢿⣿⣦⡀⠺⠟⠋⣠⣿⣿⠏⣠⣾⠀
⠀⠀⠀⠀⠀⠀⠀⢤⣾⠿⠿⠟⠋⢉⣀⣤⣄⠙⢿⣿⣦⡀⠐⢿⠿⢃⣼⣿⡿⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⠟⠋⠀⠀⠙⢿⣿⣷⣄⠀⠸⣿⠟⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠛⠉⠉⣠⣴⣶⣾⣿⡿⠗⠀⠙⠻⣿⣿⣦⣀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠚⠛⠛⠛⠉⠁⠀⠒⠛⠛⠂⠈⠙⠛⠛⠓⠂⠀
    _____  ___  ____   ____  
   |     |/  _]|    \ |    \ 
   |   __/  [_ |  D  )|  _  |
   |  |_|    _]|    / |  |  |
   |   _]   [_ |    \ |  |  |
   |  | |     ||  .  \|  |  |
   |__| |_____||__|\_||__|__|
```
# Fern

`fern` is a swiss-army knife for your notetaking and personal knowledge management. Fern is a commandline tool to manage, curate, and search a vault of your personal notes. It offers an alternative to heavier GUI-based notetaking management applications. It was designed for systems that are resource constrained or for users that value the privacy and security of their data.

Fern has support for daily Journals (think a Engineer's log), Templates, and Bookmarking Notes. It has a RegEx compatable full-text search of Notes to find records in your Vault.

## Installing Fern

1. Clone this repo.
    ```sh
    git clone https://git.sr.ht/~bugwhisperer/fern
    ```
2. Change into this repo directory.
    ```sh
    cd fern
    ```
3. Install using Make
    ```sh
    make install          # Install to ~/.local (user install)
    # OR
    make install-system   # Install system-wide (requires sudo)
    ```
4. Setup a new Fern Vault.
    ```sh
    fern vault create <path-to-vault-folder>
    ```

### Installation Options
- `make install` - Installs to `~/.local` (recommended for single user)
- `make install-system` - Installs system-wide to `/usr/local` (requires sudo)
- `make install PREFIX=/custom/path` - Install to custom location
- `make uninstall` - Remove user installation
- `make uninstall-system` - Remove system installation

## Using Fern
After installing fern, run `fern help` or the manpage documentation (you _did_ install the manpage, didn't you?), `man fern` for more guidance on using fern.

## Found a bug? Feature idea?
Please open any tickets for bugs found or feature requests here: [https://todo.sr.ht/~bugwhisperer/Fern-Issues](https://todo.sr.ht/~bugwhisperer/Fern-Issues).

