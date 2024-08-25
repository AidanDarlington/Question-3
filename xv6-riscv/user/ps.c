#include "kernel/types.h"
#include "user/user.h"

// Aidan Darlington
// StudentID: 21134427
// Function to check arguments to send to the function
int main(int argc, char *argv[]){
  if (argc == 1) {
    ps(0);
  } else if (argc == 2 && strcmp(argv[1], "-r") == 0) {
    ps(1);
  } else {
    // Invalid Argument
    printf("Wrong command option\n");
    exit(1);
  }
  exit(0);
}
