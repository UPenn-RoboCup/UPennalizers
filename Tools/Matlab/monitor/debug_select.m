function debug_select(varargin)
  global h_button DB_SELECT;
  DB_SELECT = 1 - DB_SELECT;
  if DB_SELECT>0
    set(h_button,'String', 'BALL');
  else
    set(h_button,'String', 'GOAL');
  end
end
