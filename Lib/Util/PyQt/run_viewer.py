#!/usr/bin/python -d

import sys
from PyQt4 import QtCore, QtGui
from viewer import Ui_MainWindow

class MainWindow(QtGui.QMainWindow):
  def __init__(self, win_parent = None):
    #Init the base class
    QtGui.QMainWindow.__init__(self, win_parent)

if __name__ == "__main__":
  app = QtGui.QApplication(sys.argv)
  main_window = MainWindow()
  myapp = Ui_MainWindow()

  # Setup the UI
  myapp.setupUi( main_window )

  main_window.show()
  sys.exit(app.exec_())
