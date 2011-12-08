/*
  x = naoComm;

  MEX file to send and receive UDP messages.
  Daniel D. Lee, 6/09 <ddlee@seas.upenn.edu>
*/

#include "libMonitor.h"

#include <string>
#include <deque>
#include "string.h"
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

const int maxQueueSize = 16;

static std::deque<std::string> recvQueue;
static int send_fd, recv_fd;

static sockaddr_in source_addr;
static char data[MAX_LENGTH];


void close_comm(){
  if (send_fd > 0)
    close(send_fd);
  if (recv_fd > 0)
    close(recv_fd);
}

int init_comm(){

  struct hostent *hostptr = gethostbyname(IP);
    if (hostptr == NULL)
      return -5;
      
    send_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (send_fd < 0)
      return -6;

    int i = 1;
    if (setsockopt(send_fd, SOL_SOCKET, SO_BROADCAST,
		   (const char *) &i, sizeof(i)) < 0)
      return -7;

    struct sockaddr_in dest_addr;
    bzero((char *) &dest_addr, sizeof(dest_addr));
    dest_addr.sin_family = AF_INET;
    bcopy(hostptr->h_addr, (char *) &dest_addr.sin_addr, hostptr->h_length);
    dest_addr.sin_port = htons(PORT);
    if (connect(send_fd, (struct sockaddr *) &dest_addr, sizeof(dest_addr)) < 0){
      return -1;
    }

    recv_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (recv_fd < 0)
      return -2;

    struct sockaddr_in local_addr;
    bzero((char *) &local_addr, sizeof(local_addr));
    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port = htons(PORT);
    if (bind(recv_fd, (struct sockaddr *) &local_addr,sizeof(local_addr)) < 0){
      return -3;
    }

    // Nonblocking receive:
    int flags  = fcntl(recv_fd, F_GETFL, 0);
    if (flags == -1) flags = 0;
    if (fcntl(recv_fd, F_SETFL, flags | O_NONBLOCK) < 0){
      return -4;
    }

  return 0;

}

void process_message(){

  socklen_t source_addr_len = sizeof(source_addr);
  int len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
      (struct sockaddr *) &source_addr, &source_addr_len);
  while (len > 0) {
    std::string msg((const char *) data, len);
    recvQueue.push_back(msg);

    len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
        (struct sockaddr *) &source_addr, &source_addr_len);
  }

  // Remove older messages:
  while (recvQueue.size() > maxQueueSize) {
    recvQueue.pop_front();
  }
}

int send_message( void* data, int num_data ){
  return send(send_fd, data, num_data, 0);
}

int getQueueSize(){
  return recvQueue.size();
}

int queueIsEmpty(){
  return recvQueue.empty();
}

int get_front_size(){
  return recvQueue.front().size();
}

const void* get_front_data(){
  return recvQueue.front().c_str();
}

void pop_data(){
  recvQueue.pop_front();
}

