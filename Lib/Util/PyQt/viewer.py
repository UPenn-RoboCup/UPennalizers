# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'viewer.ui'
#
# Created: Sun Jan  2 20:44:35 2011
#      by: PyQt4 UI code generator 4.6
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui
import vcm
width = 640
height = 480

class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize( 2*width + 30, height + 75)
        self.centralwidget = QtGui.QWidget(MainWindow)
        self.centralwidget.setObjectName("centralwidget")

        # Add the actual image
        self.widget = QtGui.QWidget(self.centralwidget)
        self.widget.setGeometry(QtCore.QRect(10, 10, width, height))
        self.widget.setObjectName("widget")
        # Add the inital label (the image) after the UI is instantiated
        self.widget.label = QtGui.QLabel(self.widget)
        camera_frame = vcm.image('big_img')
        self.qimg = QtGui.QImage(camera_frame, width, height, QtGui.QImage.Format_RGB32)
        frame_pixmap = QtGui.QPixmap.fromImage(self.qimg)
        rot = QtGui.QMatrix()
        self.frame_pixmap = frame_pixmap.transformed( rot.rotate( 180 ) )
        self.widget.label.setPixmap(self.frame_pixmap)

        # Add the labelled image
        self.labelV = QtGui.QWidget(self.centralwidget)
        self.labelV.setGeometry(QtCore.QRect(width+20, 10, width/2, height))
        self.labelV.setObjectName("labeled")
        # Add the inital label (the image) after the UI is instantiated
        self.labelV.label = QtGui.QLabel(self.labelV)
        label_frame = vcm.label('big_labelA')
        self.qimg = QtGui.QImage(label_frame, width/2, height, QtGui.QImage.Format_RGB32)
        frame_pixmap = QtGui.QPixmap.fromImage(self.qimg)
        rot = QtGui.QMatrix()
        frame_pixmap = frame_pixmap.transformed( rot.rotate( 180 ) )
        self.labelV.label.setPixmap( frame_pixmap )

        # Update Button
        self.pushButton = QtGui.QPushButton(self.centralwidget)
        self.pushButton.setGeometry(QtCore.QRect(20, height+20, 92, 28))
        self.pushButton.setObjectName("pushButton")
        # Add the click event
        QtCore.QObject.connect(self.pushButton, QtCore.SIGNAL("clicked()"), self.on_update_clicked)

        # Save Button
        self.saveButton = QtGui.QPushButton(self.centralwidget)
        self.saveButton.setGeometry(QtCore.QRect(120, height+20, 92, 28))
        self.saveButton.setObjectName("saveButton")
        # Add the click event
        QtCore.QObject.connect(self.saveButton, QtCore.SIGNAL("clicked()"), self.on_save_clicked)
        self.num = 1


        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QtGui.QMenuBar(MainWindow)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 400, 25))
        self.menubar.setObjectName("menubar")
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QtGui.QStatusBar(MainWindow)
        self.statusbar.setObjectName("statusbar")
        MainWindow.setStatusBar(self.statusbar)

        self.retranslateUi(MainWindow)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

    def on_update_clicked(self):
        camera_frame = vcm.image('big_img')
        label_frame = vcm.label('big_labelA')
        ball_centroid = vcm.ball('centroid')
        ball_axis = vcm.ball('axisMajor')[0]
        ball_detected = vcm.ball('detect')[0]

        # Update the labels
        qimg = QtGui.QImage(label_frame, width/2, height, QtGui.QImage.Format_RGB32)
        frame_pixmap = QtGui.QPixmap.fromImage(qimg)
        rot = QtGui.QMatrix()
        frame_pixmap = frame_pixmap.transformed( rot.rotate( 180 ) )

        if(ball_detected==1):
         # Paint the crosshairs and the axis envelope
         p = QtGui.QPainter( frame_pixmap )
         p.setPen( QtGui.QColor("lightgray") )
         p.drawLine( ball_centroid[0]-10, ball_centroid[1], ball_centroid[0]+10, ball_centroid[1])
         p.drawLine( ball_centroid[0], ball_centroid[1]-10, ball_centroid[0], ball_centroid[1]+10)
         center = QtCore.QPoint(ball_centroid[0],ball_centroid[1])
         p.drawEllipse(center, ball_axis/2, ball_axis/2)
         p.end()

        self.labelV.label.setPixmap( frame_pixmap )

        # Update the image
        ball_centroid[0] = ball_centroid[0]*2

        self.qimg = QtGui.QImage(camera_frame, width, height, QtGui.QImage.Format_RGB32)
        self.frame_pixmap = QtGui.QPixmap.fromImage(self.qimg)
        rot = QtGui.QMatrix()
        self.frame_pixmap = self.frame_pixmap.transformed( rot.rotate( 180 ) )

        if(ball_detected==1):
         p = QtGui.QPainter( self.frame_pixmap )
         p.setPen( QtGui.QColor("lightgray") )
         p.drawLine( ball_centroid[0]-10, ball_centroid[1], ball_centroid[0]+10, ball_centroid[1])
         p.drawLine( ball_centroid[0], ball_centroid[1]-10, ball_centroid[0], ball_centroid[1]+10)
         center = QtCore.QPoint(ball_centroid[0],ball_centroid[1])
         p.drawEllipse(center, ball_axis/2, ball_axis/2)
         p.end()

        self.widget.label.setPixmap( self.frame_pixmap )

    def on_save_clicked(self):
        filename = '/home/robotis/Desktop/saved/Image'+str(self.num)+'.tif'
        print filename
        self.frame_pixmap.save( filename, 'tiff' )
        self.num = self.num + 1

    def retranslateUi(self, MainWindow):
        MainWindow.setWindowTitle(QtGui.QApplication.translate("MainWindow", "MainWindow", None, QtGui.QApplication.UnicodeUTF8))
        self.pushButton.setText(QtGui.QApplication.translate("MainWindow", "Update", None, QtGui.QApplication.UnicodeUTF8))

