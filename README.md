# Love2D LAN Chat System

A simple, extensible LAN chat system built using the Love2D framework. 

## 📂 Project Structure
- **/server**: The backend logic that handles incoming packets.
- **/shared**: Common utilities used by both client and server.
- **/client**: The user interface and connection logic. **(Main area for user configuration)**.

## 🛠️ Prerequisites
Before running the chat system, ensure you have the following:
1. **Love2D Installed**: Download it from [love2d.org](https://love2d.org).
2. **PATH Configured**: Add the Love2D installation folder to your system's PATH environment variables so you can run `love` from any command prompt.
3. **VS Code Extension (Recommended)**: Install the **Love2D Support** extension. This allows you to run your project by pressing `Alt + L` while a file is open.

## 🚀 Setup & Usage

### 1. Find Your Local IP Address
To connect clients to the server, you need your machine's local IP (e.g., `192.168.0.2`).
- **Windows**: Open Command Prompt and type `ipconfig`.
- **Linux/Mac**: Open Terminal and type `ifconfig` (or `ip addr`).

### 2. Configure the Client
Open `client/main.lua` and locate the `IP_ADDRESS` variable. Replace the placeholder with the local IP address you found in the previous step.

### 3. Start the Server
1. Open the `server/main.lua` file in VS Code.
2. Press `Alt + L` to launch the server instance. It is now ready to receive packets.

### 4. Start the Clients
1. Open a terminal/command prompt in the root directory of the project.
2. Run the client using:
   ```bash
   love client
