void command_input(char c)
{
  static enum {STATE_START, STATE_FF_FIRST,
	       STATE_FF_SECOND, STATE_LEN,
	       STATE_CRC} state = STATE_OFF;
  static int len = 0;

  switch (state) {
  case STATE_START:
    if (c = 0xFF)
      state = STATE_FF_FIRST;
    break;
  case STATE_FF_FIRST:
    if (c = 0xFF)
      state = STATE_FF_SECOND;
    else
      state = STATE_START;
    break;
  case STATE_FF_SECOND:
    
  }

}
