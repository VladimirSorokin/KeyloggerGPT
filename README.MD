
# KeyloggerGPT

This repository contains the source code for [Project Name]. Follow the instructions below to clone, build, and run the project on your MacOS system using Xcode.

## Prerequisites

Ensure you have the following installed on your system:
- macOS
- Xcode (including Xcode Command Line Tools)

## Getting Started

### Cloning the Repository

First, clone the repository to your local machine

### Opening the Project in Xcode

1. Open Xcode.
2. Click on `File` -> `Open`.
3. Navigate to the cloned repository folder and select it.

### Building the Project

1. With the project open in Xcode, select your target device or simulator.
2. Click on the build button (or press `Cmd + B`) to build the project.

### Running the Executable

After building the project, Xcode will generate an executable file in the build directory.

1. Locate the executable file in the Xcode build directory.
2. Copy the `config.json` file from the repository to the same directory as the executable file. Also add you openAI key for gpt api to `config.json`

### Executing the File

Navigate to the directory containing the executable and `config.json` file, and run the executable:

\`\`\`bash
./your-executable-file
\`\`\`

After first run MacOS alerts you about permission. Give permission for terminal in Settings and relaunch exec file.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
