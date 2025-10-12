#include <array>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <memory>
#include <string>

std::string exec(const char *cmd) {
  std::array<char, 128> buf;
  std::string res;
  std::unique_ptr<FILE, decltype(&pclose)> p(popen(cmd, "r"), pclose);
  if (!p)
    return "";
  while (fgets(buf.data(), buf.size(), p.get()) != nullptr) {
    res += buf.data();
  }
  if (!res.empty() && res.back() == '\n') {
    res.pop_back();
  }
  return res;
}

int main(int argc, char *argv[]) {
  bool check_numlock = false;
  bool check_capslock = false;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--numlock") == 0 || strcmp(argv[i], "-n") == 0) 
      check_numlock = true;
	else if (strcmp(argv[i], "--capslock") == 0 || strcmp(argv[i], "-c") == 0) 
      check_capslock = true;
    
  }

  if (!check_numlock && !check_capslock) 
    check_numlock = check_capslock = true;
  

  const char *numlock_cmd = "hyprctl devices -j | jq -r '.keyboards[] | "
                            "select(.main == true) | .numLock'";
  const char *capslock_cmd = "hyprctl devices -j | jq -r '.keyboards[] | "
                             "select(.main == true) | .capsLock'";

  std::string prev_state;

  std::string state;

  if (check_numlock && check_capslock)
    state = exec(numlock_cmd) + " " + exec(capslock_cmd);
  else if (check_numlock)
    state = exec(numlock_cmd);
  else
    state = exec(capslock_cmd);

  std::cout << state << std::endl;

  return 0;
}
