import pyshm
import numpy as np


class ShmWrapper():
  s = 'def test(self): return "test";'
  exec s
  def __init__(self, name):
    ''' initialize shared memory segment wrapper '''
    try:
      self.handle = pyshm.open(name);
    except RuntimeError, err:
      print('Shared Memory Segment doesn\'t exist: %s' % err);
      return;

    # generate accessors and setters
    self.__generate_accessors_setters();


  @staticmethod
  def _format_output(ret):
    ''' 
      formats the return to make it easier to use than just a list

      converts lists to numpy ndarray
      any return of lentgth 1 is returned as just the number
    '''
    if (len(ret) == 1):
      return ret[0];
    else:
      return np.asarray(ret);


  @staticmethod
  def _format_input(vals):
    '''
      makes sure the input is in the correct format

      pyshm.set only accepts 1 dimensional python lists of doubles
    '''
    if (type(vals) == list):
      return vals;
    if (type(vals) == np.ndarray):
      return vals.flatten.tolist();
    if (hasattr(vals, '__iter__')):
      # cast as a list (mainly support for tuples)
      return list(vals);

    # at list point assume it is a number
    return [vals];

  


  def __generate_accessors_setters(self):
    '''
      generate accessors and settors for each key in the shared
      memory segment.

      result will be
      self.get_[key]()
      self.set_[key](vals)
    '''
    key = pyshm.next(self.handle);
    while (key != ''):
      # create assessor
      accessor = ("self.get_%s = lambda : ShmWrapper._format_output(pyshm.get(%d, '%s'));" % (key, self.handle, key));
      exec accessor;
      # create setter
      setter = ("self.set_%s = lambda vals : pyshm.set(%d, '%s', ShmWrapper._format_input(vals));" % (key, self.handle, key));
      exec setter;

      # get next key
      key = pyshm.next(self.handle, key);

