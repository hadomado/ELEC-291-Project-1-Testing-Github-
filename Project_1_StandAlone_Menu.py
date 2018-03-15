# -*- coding: utf-8 -*-
"""
Created on Thu Feb  8 16:30:46 2018

@author: Jerricho
"""
import tkinter as tk
from tkinter import StringVar, IntVar
import csv
import serial
import serial.tools.list_ports as st

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Global Variables
presets = {}
preset_list = []

grey_color = '#bababa'
background_color = '#2288d8'
entry_color = 'white'
PORT = 'COM6'

start_menu = False

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Funcitons
def Load_Presets():
    with open("Test_File.txt",'r') as preset_file:
        for line in preset_file:
            x = line.split(",")
            a = x[0]
            b = x[1:6]
            presets[a] = b
            preset_list.append(a)
            
def Save_Presets():
    with open("Test_File.txt", 'w') as preset_file:
        preset_writer = csv.writer(preset_file, lineterminator = '\n')
        for preset in preset_list:
            preset_writer.writerow([preset]+presets[preset]+[''])
    print('Save Sucessful')


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Classes
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
        y = (self.master.winfo_screenheight()-self.master.winfo_reqheight())/4
        self.master.geometry(f"+{int(x)}+{int(y)}")
        
        #self.master.config(menu= tk.Menu(self.master))
        
        self.pack()                         
        self.master.title("Main Menu")
        #_____________________________________________________________________
        #   Dialog Box
        
        my_dialog_frame = tk.Frame(self)
        my_dialog_frame.pack(padx = 50, pady = 50)
        tk.Label(my_dialog_frame, textvariable=self.blurb, font = ('',18), background = background_color).pack()
        
        #_____________________________________________________________________
        #   Buttons
        my_preset_frame = tk.Frame(self)
        my_preset_frame.pack(padx =15, pady = (0,15), anchor = 'e')
        tk.Button(my_preset_frame, text='Preset 1', font = ('Times',12), command = self.click_preset_1, background = background_color).pack(side = 'left')
        tk.Button(my_preset_frame, text='Preset 2', font = ('Times',12), command = self.click_preset_2, background = background_color).pack(side = 'left')
        tk.Button(my_preset_frame, text='Preset 3', font = ('Times',12), command = self.click_preset_3, background = background_color).pack(side = 'left')
        tk.Button(my_preset_frame, text='Pizza Menu', font = ('Times',12), command = self.click_preset_4, background = background_color).pack(side = 'left')
        
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
        self.blurb.set('Pizza Menu')
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

    def popup(self):
        toplevel = tk.Toplevel() 
        xx = 850
        yy = 420
        toplevel.geometry(f"+{int(xx)}+{int(yy)}")
        toplevel.configure(background = grey_color)
        new_label = tk.Label(toplevel, text = 'Warning, you have not saved \n Would you like to save?', font = ('',15), background = grey_color)
        new_label.pack(pady = [10,0])
        save_button = tk.Button(toplevel, text = 'Save', font = ('',12), background = grey_color, command = self.save_and_exit)
        save_button.pack(padx = [50,0], pady = 10, side = 'left')
        exit_button = tk.Button(toplevel, text = 'Exit', font = ('',12), background = grey_color, command = self.user_exit)
        exit_button.pack(side = 'left')
        cancel_button = tk.Button(toplevel, text = 'Cancel', font = ('',12), background = grey_color, command = toplevel.destroy)
        cancel_button.pack(side = 'left')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#class Pre_Menu(tk.Frame):
    
    
#    def __init__(self, master):
#        tk.Frame.__init__(self, master)
            
#        self.configure(background = background_color)
        #w, h = 700,320
        #self.geometry.master(f"+{int(w)}+{int(h)}")
                    
#        self.screen_text = StringVar()
#        self.screen_text.set('Waiting for response')
                    
#        tk.Label(self, textvariable = self.screen_text, font = ('',12), background = background_color).pack(padx = 25, pady = 25)
#        tk.Button(self,text = 'Refresh', font = ('',12),background = background_color, command = self.click_refresh).pack(side = 'right')
#        tk.Button(self, text = 'Exit', font = ('',12), background = background_color, command = self.master.destroy).pack(side = 'right')
                
#    def click_refresh(self):
#       strin = ser.readline();
#       print(strin.decode('ascii'));
        
#        if strin.decode('ascii') == 'Hello, World!'+ '\r'+ '\n':
#           global start_menu
#           start_menu = True
#           self.screen_text.set('Device Found')

#        else:
#            self.screen_text.set('No response, keep waiting?')
    
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
#   MAIN
if __name__ == '__main__':
    try:
        open('')
    Load_Presets()
    my_root = tk.Tk()
    my_app = App(my_root)
    my_app.mainloop()
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#   insert spi code here


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
#   Menu starts here
    
        
    
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#   Graph Code runs here
    
    print('this code runs after the menu')