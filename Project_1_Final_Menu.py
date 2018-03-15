# -*- coding: utf-8 -*-
"""
Created on Thu Feb  8 16:30:46 2018
@author: Jerricho
Group Members: Jerry Luo, Wesley Britton, JaQi , Norton Huang, Paul Wang, John Shen
Purpose:
    This menu is intended to support our Project 1 micro-controller for reflow soldering oven
    This menu will act as an alternative menu for the micro-controller's LCD screen
Funcitons:
    Upon program start, Python will be idle until a signal is received from the micro-controller.
    Upon receiving the signal, a menu will open with all the reflow parameters
    Toggle between pre-sets by click on pre-set number
    Any data written and saved will overwrite previous data
    Upon closing menu, menu can be restarted by pressing reset on the microcontroller (unless in demo mode)
    Upon pressing send, the current pre-set will be saved and sent to micro-controller
    Upon pressing start reflow, the current SAVED pre-set will be sent to micro-controller and reflow will begin
    After reflow has started, menu will close automatically and oven temperature will be graphed in a second window
    
Other Notes:
    Due to time constraints, the micro-controller menu must be in Python Mode! if not, the graph will not open
    If the micro-controller is not in Python Mode, please open and use Project_1_grapher.py
    Please include Presets.txt in the same directory as Project_1_Final_Menu.py
    Please connect micro-controller to port: com 6 
    Please set 'just_demo_menu' to True if there is no micro-controller attached (this is demo mode)
"""

import tkinter as tk
from tkinter import StringVar, IntVar
import csv
import serial
import serial.tools.list_ports as st

#import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys
#import time, math

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Global Variables
presets = {}    #this is a dictionary john
preset_list = []    #this is a list john

grey_color = '#bababa'
background_color = '#2288d8'
entry_color = 'white'
PORT = 'COM6'

Text_File = 'Presets.txt'

start_menu = False

just_demo_menu = True
#If True, Will bypass communication with micro-controller

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Funcitons
#   Opens presets (Text_File) and stores data in Presets dictionary  
def Load_Presets():
    global preset_list
    global presets
    try:
        preset_file = open(Text_File,'r')
        for line in preset_file:
            x = line.split(",")
            index = x[0]
            values = x[1:6]
            for num in range(0,5):
                values[num] = int(values[num])
            presets[index] = values
            preset_list.append(index)
        preset_file.close()
    except:
        print("No Preset File Found!, Creating Blank Preset File")
        preset_list = preset_list+['preset 1', 'preset 2', 'preset 3', 'preset 4']
        line = '0,0,0,0,0,0'
        values = line.split(",")
        for index in preset_list:
            for num in range(0,5):
                values[num] = int(values[num])
            presets[index] = values
            
#   Opens presets file and writes the contents of Presets dictionary into Text_File
def Save_Presets():
    with open(Text_File, 'w') as preset_file:
        preset_writer = csv.writer(preset_file, lineterminator = '\n')
        for preset in preset_list:
            preset_writer.writerow([preset]+presets[preset]+[''])
    print('Save Sucessful')

#   Opens serialport via PySerial. Port accessed through global variable 'ser'
def data_gen():
    global ser
    t = data_gen.t
    while True:
       t+=1
       if(just_demo_menu == False):
           strin = ser.readline();
           val=int(strin)
       else:
           val = 0
       yield t, val
       
#   Graphs the variable data and updates the graph
def run_graph(data):
    # update the data
    t,y = data
    if t>-1:
        xdata.append(t)
        ydata.append(y)
        if t>xsize: # Scroll to the left.
            ax.set_xlim(t-xsize, t)
        line.set_data(xdata, ydata)

    return line,

def on_close_figure(event):
    sys.exit(0)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Classes
    
#   TK Class: This is the Menu
class App(tk.Frame):
    
    
    def __init__(self, master):
        
        #class variables
        self.blurb = StringVar()
        self.blurb.set('Preset 1')
        
        self.state = IntVar()
        self.state.set(1)
        
        self.preheat = IntVar()
        self.preheat.set(presets[preset_list[self.state.get()-1]][0])
        
        self.soak = IntVar()
        self.soak.set(presets[preset_list[self.state.get()-1]][1])
        
        self.peak_temp = IntVar()
        self.peak_temp.set(presets[preset_list[self.state.get()-1]][2])
        
        self.peak_time = IntVar()
        self.peak_time.set(presets[preset_list[self.state.get()-1]][3])
        
        self.liquid = IntVar()
        self.liquid.set(presets[preset_list[self.state.get()-1]][4])
        
        self.saved = True        
        #_____________________________________________________________________
        #   Window Configurations
        
        
        tk.Frame.__init__(self, master)
        
        self.master.protocol('WM_DELETE_WINDOW', self.click_exit)
        
        self.master.resizable(False, False)
        #self.master.tk_setPalette(background = '#2288d8')
        self.configure(background = background_color)
        x = (self.master.winfo_screenwidth()-self.master.winfo_reqwidth())/2
        y = (self.master.winfo_screenheight()-self.master.winfo_reqheight())/5
        self.master.geometry(f"+{int(x)}+{int(y)}")
        
        #self.master.config(menu= tk.Menu(self.master))
        
        self.pack()                         
        self.master.title("Oven Controller")
        #_____________________________________________________________________
        #   Dialog Box
        
        my_dialog_frame = tk.Frame(self)
        my_dialog_frame.pack(padx = 50, pady = 50)
        tk.Label(my_dialog_frame, textvariable=self.blurb, font = ('Times',20), background = background_color).pack()
        
        #_____________________________________________________________________
        #   Buttons
        my_preset_frame = tk.Frame(self)
        my_preset_frame.pack(padx =15, pady = (0,15), anchor = 'e')
        tk.Button(my_preset_frame, text='Preset 1', font = ('Times',12), command = self.click_preset_1, background = background_color).pack(side = 'left')
        tk.Button(my_preset_frame, text='Preset 2', font = ('Times',12), command = self.click_preset_2, background = background_color).pack(side = 'left')
        tk.Button(my_preset_frame, text='Preset 3', font = ('Times',12), command = self.click_preset_3, background = background_color).pack(side = 'left')
        tk.Button(my_preset_frame, text='Reheat Pizza', font = ('Times',12), command = self.click_preset_4, background = background_color).pack(side = 'left')
        
        #_____________________________________________________________________
        #   Entry Box
        my_entry_frame = tk.Frame(self)
        my_entry_frame.configure(background = background_color)
        my_entry_frame.pack(padx = 60, pady = 30)
        tk.Label(my_entry_frame, text = 'Preheat Temperature', font = ('',12), background = background_color).pack()
        tk.Entry(my_entry_frame, textvariable = self.preheat, font = ('',12), background = entry_color).pack()
        
        tk.Label(my_entry_frame, text = 'Soak Time', font = ('',12), background = background_color).pack()
        tk.Entry(my_entry_frame, textvariable = self.soak, font = ('',12), background = entry_color).pack()
        
        tk.Label(my_entry_frame, text = 'Peak Temperature', font = ('',12), background = background_color).pack()
        tk.Entry(my_entry_frame, textvariable = self.peak_temp, font = ('',12), background = entry_color).pack()
        
        tk.Label(my_entry_frame, text = 'Peak Time', font = ('',12), background = background_color).pack()
        tk.Entry(my_entry_frame, textvariable = self.peak_time, font = ('',12), background = entry_color).pack()
        
        tk.Label(my_entry_frame, text = 'Liquid Temperature', font = ('',12), background = background_color).pack()
        tk.Entry(my_entry_frame, textvariable = self.liquid, font = ('',12), background = entry_color).pack()
        
        #_____________________________________________________________________
        #   Other buttons
        
        my_button_frame = tk.Frame(self)
        my_button_frame.pack(padx = 50, pady = 30)
        my_button_frame.configure(background = background_color)
        tk.Button(my_button_frame, text = 'Exit', command = self.click_exit, font = ('',12), background = background_color).pack(side = 'right')
        tk.Button(my_button_frame, text = 'Save', command = self.click_save, font = ('',12), background = background_color).pack(side = 'right')
        tk.Button(my_button_frame, text = 'Update', command = self.click_update, font = ('',12), background = background_color).pack(side = 'right')
        #tk.Button(my_button_frame, text = 'test button', command = self.popup).pack()
        
        my_flash_frame = tk.Frame(self)
        my_flash_frame.pack(padx = 50, pady = 30)
        my_flash_frame.configure(background = background_color)
        tk.Button(my_flash_frame, text = 'Send', command = self.send_data, font = ('',12), background = background_color).pack(side = 'right')
        tk.Button(my_flash_frame, text = 'Reflow', command = self.start_reflow, font = ('',12), background = background_color).pack(side = 'right')
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #class methods
        
    def set_all(self):
        self.preheat.set(presets[preset_list[self.state.get()-1]][0])
        self.soak.set(presets[preset_list[self.state.get()-1]][1])
        self.peak_temp.set(presets[preset_list[self.state.get()-1]][2])
        self.peak_time.set(presets[preset_list[self.state.get()-1]][3])
        self.liquid.set(presets[preset_list[self.state.get()-1]][4])
    
    def click_preset_1(self):
        self.blurb.set('Preset 1')
        self.state.set(1)
        self.set_all()
        
    def click_preset_2(self):
        self.blurb.set('Preset 2')
        self.state.set(2)
        self.set_all()
        
    def click_preset_3(self):
        self.blurb.set('Preset 3')
        self.state.set(3)
        self.set_all()
        
    def click_preset_4(self):
        self.blurb.set('Reheat Pizza')
        self.state.set(4)
        self.set_all()
        
    def click_exit(self):
        if self.saved == False:
            self.popup()
        else:
            self.user_exit()
    
    def click_save(self):
        self.click_update()
        Save_Presets()
        self.saved = True
        
    def user_exit(self):
        print('user has exited')
        self.master.destroy()
    
    def click_update(self):
        presets[preset_list[self.state.get()-1]][0] = self.preheat.get()
        presets[preset_list[self.state.get()-1]][1] = self.soak.get()
        presets[preset_list[self.state.get()-1]][2] = self.peak_temp.get()
        presets[preset_list[self.state.get()-1]][3] = self.peak_time.get()
        presets[preset_list[self.state.get()-1]][4] = self.liquid.get()
        self.saved = False
        
    def save_and_exit(self):
        self.click_save()
        self.click_exit()
        
    def start_reflow(self):
        global ser
        data_out = bytearray([63])
        print(data_out)
        if(just_demo_menu == False):
            ser.write(data_out)
        else:
            print("Just Demo Menu, No actual Output")
        self.user_exit()
        
    def send_data(self):
        global ser
        self.click_save()
        data_out = bytearray([77]+presets[preset_list[self.state.get()-1]])
        print(data_out)
        if(just_demo_menu == False):
            ser.write(data_out)
        else:
            print("Just Demo Menu, No actual Output")

    def popup(self):
        toplevel = tk.Toplevel() 
        xx = 880
        yy = 420
        toplevel.geometry(f"+{int(xx)}+{int(yy)}")
        toplevel.configure(background = grey_color)
        new_label = tk.Label(toplevel, text = 'Warning, you have not saved \n Would you like to save?', font = ('',15), background = grey_color)
        new_label.pack(pady = [10,0])
        save_button = tk.Button(toplevel, text = 'Save', font = ('',12), background = grey_color, command = self.save_and_exit)
        save_button.pack(padx = [70,0], pady = 10, side = 'left')
        exit_button = tk.Button(toplevel, text = 'Exit', font = ('',12), background = grey_color, command = self.user_exit)
        exit_button.pack(side = 'left')
        cancel_button = tk.Button(toplevel, text = 'Cancel', font = ('',12), background = grey_color, command = toplevel.destroy)
        cancel_button.pack(side = 'left')


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
#   MAIN
if __name__ == '__main__':
    Load_Presets()
    my_root = tk.Tk()
    my_app = App(my_root)
    
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#   SPI CODE HERE
    if(just_demo_menu == False):
        try:
            global ser
            ser.close();
        except:
            print('exception')
            
        try:
            ser = serial.Serial(PORT,115200,timeout = 100)
        except:
            print('Serial port %s is not avaliable' % PORT)
            portlist = list(st.comports())
            print('Trying with %s' % portlist[0][0])
            ser = serial.Serial(portlist[0][0], 115200, timeout = 100)
        ser.isOpen()
    
    #bypass
    else:
        start_menu = True
    
    while start_menu == False:
        strin = ser.readline();
        
        if strin.decode('ascii') == 'Start Code'+ '\r'+ '\n':
            start_menu = True
            print('Device Found, Starting Menu')

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
#   Menu starts here
    my_app.mainloop()
        
    
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#   Graph Code runs here
    
    print('this code runs after the menu')
    xsize=250
    

    #if 1 == 2:
    data_gen.t = -1
    fig = plt.figure()
    fig.canvas.mpl_connect('close_event', on_close_figure)
    ax = fig.add_subplot(111)
    line, = ax.plot([], [], lw=2)
    ax.set_ylim(0, 300)
    ax.set_xlim(0, xsize)
    ax.grid()
    xdata, ydata = [], []
        
    # Important: Although blit=True makes graphing faster, we need blit=False to prevent
    # spurious lines to appear when resizing the stripchart.
        
    ani = animation.FuncAnimation(fig, run_graph, data_gen, blit=False, interval=100, repeat=False)
    plt.show()




