/*
 * Takes a command value and any parameters and executes the command with given perimeters.
 * It also takes in the computer to allow for operations on the computers state
 * It returns the output line of the command, and the updated computer
 * In some cases, it might modify commandLines cache for multi line operations
 */

private [_arg,_computer];

_arg = _this select 0;
_cmd = _arg select 0;
_computer = _this select 1;

_commandLine = _computer select 5;
_cache = _commandLine select 6;

_users = _computer select 0;
_user = _computer select 2;

_remainingLine = [_arg select 1] call Line_fnc_inputToString;
_params = [_remainingLine] call Line_fnc_parseSpaceDeliniation;

_output = "The command you entered is not recognised as a command. Type 'HELP' in order to see a list of supported commands.";

if(!(_cache select 0))then{
	switch true do {
		case(str(_cmd) == str("QUIT")):{
		
			_computer set[4,"QUIT"];
			
			_output = "";
		};
		case(str(_cmd) == str("HELP")):{
			_output = "Supported Commands:<br/>"+
				"  HELP               Displays all supported commands<br/>"+
				"  TIME               Displays the current date and time   m/d/y hr:min<br/>"+
				"  WHOAMI             Displays the current active user's user name <br/>"+
				"  COLOR              Toggles color of text between green and white<br/>"+
				"  LS                 Displays all files in current active directory<br/>" +
				"  CD [DirName]       Opens the specified directory, no [] braces, 'cd ..' returns you to the parent directory<br/>" +
				"  RN [DirName] [NewName]   Renames the directory matching the first parameter with the name specified in the second parameter, no [] braces<br/>" +
				"  MKDIR [DirName]    Creates a new directory in the current active directory with specified dirName, no [] braces<br/>" +
				"  RM [DirName]       permanently deletes the specified subdirectory from the current directory<br/>"+
				"  STEED [FileName]   If specified file exists and is not a directory, opens it in Simulated TExt EDitor (STEED), if the specified file does not exist, it creates it and opens the new blank file in STEED<br/>" +
				"                     For more information on steed, type 'HELP STEED' without the quotes<br/>"+
				"  USERADD            Prompts user for input for user name, password and password confirmation, then generates a new user<br/>"+
				"  LOGIN              Prompts user for input for user name and password, if both are correct, logs in as user<br/>"+
				"  LOGOUT             Logs current user out and return to the master directory, if no user is logged in, nothing happens.<br/>"+
				"  QUIT               Exits the terminal<br/>"+
				"When specifying arguments, the '\' key is the escape character. You can press this to allow for spaces in your arguments by typing '\ '";
		};
		case(str(_cmd) == str("TIME")):{
			_date = date;				// [year, month, day, hour, minute]
			_year = _date select 0;
			_month = _date select 1;
			_day = _date select 2;
			_hour = _date select 3;
			_minute = _date select 4;
			
			if(_minute < 10)then{ _minute = "0"+str(_minute);};				//Format time right
			
			_output = format ["%1/%2/%3  %4:%5",_month,_day,_year,_hour,_minute];
		};
		case(str(_cmd) == str("WHOAMI")):{
			_output = "No user currently logged in.";
			
			if(_user != "PUBLIC")then{
				_output = _user;		//Get current User
			};
			
			_output;
		};
		case(str(_cmd) == str("COLOR")):{
			_color = _computer select 6;
			_output = "";
			
			if(_color == "#33CC33")then{
				_color = "#FFFFFF";			//White
			}else{
				_color = "#33CC33";			//Green
			};
			
			_computer set [6, _color];
			
			_output;
		};
		case(str(_cmd) == str("LS")):{
			_commandLine = _computer select 5;
			_filePath = _commandLine select 2;
			_files = _computer select 1;
			
			_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;
			_output = "";
			_inc = 0;
			
			{
				_inc = _inc + 1;				//To account for last line not needing a br
				_fileName = str(_x select 0);	//Converts from errorString to string with extra ""
				_fileName = _fileName select [1,(count _fileName - 2)];	//Removes extra ""

				if(_inc != count(_curDir select 1))then{		//if not the last subDirectory
					_output = _output + _fileName + "<br/>";
				}else{
					_output = _output + _fileName;
				};
			}forEach ([_curDir] call File_fnc_getContents);
			
			if(_output == "")then{
				_output = "No files in directory";
			};
			
			_output;
		};
		case(str(_cmd) == str("CD")):{
		
			_commandLine = _computer select 5;
			_filePath = _commandLine select 2;
			_files = _computer select 1;
			
			_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;
			_fileName = [_arg select 1] call Line_fnc_inputToString;
			_fileName = _params select 0;
			
			if(_fileName == ".." || _fileName == "../")then{
				if(count _filePath > 1)then{					//If not in MASTER
					_filePath set [count _filePath - 1, ""];
					_filePath = _filePath - [""];
					_output = "";
				}else{											//If in MASTER
					_output = "Already in root directory";
				};
			}else{
				_file = [_curDir,_fileName] call File_fnc_getFile;
				if(str(_file) != str(0))then{						//If you can find a file with specified name
					if([_file] call File_fnc_getType)then{			//If specified file found and is a directory
						if(str(_file select 2) == str(_user) || str(_file select 2) == str("PUBLIC"))then{
							_filePath = _filePath + [_file select 0];
							_output = "";
						}else{
							_output = "You do not have permission to enter this directory";
						};
					}else{											//If specified file found but not a directory
						_output = "Not a directory";
					};
				}else{												//If the specified file could not be found
					_output = "No such file or directory";
				};
			};
			
			_commandLine set[2, _filePath];
			_computer set[5, _commandLine];
			
			_output;
		};
		case(str(_cmd) == str("RN")):{
			
			_output = "";
			
			_commandLine = _computer select 5;
			_filePath = _commandLine select 2;
			_files = _computer select 1;
			
			_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;
			

			
			_prevName = _params select 0;
			_newName = _params select 1;
			
			switch(true)do{
				case(str([_curDir,_prevName] call File_fnc_getFile) == str(0)):{		//If no file name given
					_output = "Unspecified File Name";
				};
				case(count _params < 2):{												//If no new file name given
					_output = "No new name specified for file";
				};
				case(str([_curDir,_newName] call File_fnc_getFile) != str(0)):{			//If the new file name exists in the current directory
					_output = "New file name already exists in current directory";
				};
				case(str(([_curDir,_prevName] call File_fnc_getFile) select 2) != str("PUBLIC") && str(([_curDir,_prevName] call File_fnc_getFile) select 2) != str(_user)):{
																					//You do not have permission to remove the specified file
					_output = "You lack the required permission to rename the specified file";
				};
				case(str([_curDir,_prevName] call File_fnc_getFile) != str(0)):{		//If the file exists and the new name is not in the current directory
					_theFile = [_curDir,_prevName] call File_fnc_getFile;
					_theFile set[0, _newName];											//By a miracle, sqf understood that I wanted a reference and not a copy for this variable
																						//the file structure is updated from this line
					_output = "File name changed from '" + _prevName + "' to '" + _newName + "'.";
				};
			};
			
			_output;
		};
		case(str(_cmd)==str("MKDIR")):{
			_output = "";
			
			_commandLine = _computer select 5;
			_filePath = _commandLine select 2;
			_files = _computer select 1;
			
			_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;

			_newFileName = _params select 0;
			
			switch(true)do{
				case(_newFileName == ""):{													//No file name given
					_output = "Unspecified File Name";
				};
				case(str([_curDir,_newFileName] call File_fnc_getFile) != str(0)):{			//File name is already a file
					_output = "New file name already exists in current directory";
				};
				case(_newFileName == "MASTER"):{											//New file name is MASTER
					_output = "MASTER cannot be used as a subdirectory name, MASTER is reserved for the root directory";
				};
				case(_newFileName != "" && str([_curDir,_newFileName] call File_fnc_getFile) == str(0)):{	//File name is unique in current directory
					_newFile = [_newFileName,[],_user];
					(_curDir select 1) set[count (_curDir select 1), _newFile];
				};
			};
			_output;
		};
		case(str(_cmd)==str("RM")):{
			_output = "";
			
			_commandLine = _computer select 5;
			_filePath = _commandLine select 2;
			_files = _computer select 1;
			
			_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;
			
			_rmFile = _params select 0;
			
			switch(true)do{
				case(_rmFile == ""):{												//No file name specified
					_output = "Unspecified file name";
				};
				case(str([_curDir,_rmFile] call File_fnc_getFile) == str(0)):{		//Specified name does not exist
					_output = "Specified file name does not exist";
				};
				case(str([_curDir,_rmFile] call File_fnc_getFile select 2) != str("PUBLIC") && str([_curDir,_rmFile] call File_fnc_getFile select 2) != str(_user)):{
																					//You do not have permission to remove the specified file
					_output = "You lack the required permission to delete the specified file";
				};
				case(str([_curDir,_rmFile] call File_fnc_getFile) != str(0)):{		//Specified file name does exist
					_output = "Deleting this file will permanently erase all of its contents.";
					_cache = [true, "RM", "Confirm you want to delete this file (y/n) : ",_rmFile];
					_commandLine set[6,_cache];
					//Doesnt actually remove the file in this function, simply caches data for later
				};
			};
			_output;
		};
		case(str(_cmd)==str("STEED")):{
			_output = "";
			
			_zfileName = _params select 0;
			
			_commandLine = _computer select 5;
			_filePath = _commandLine select 2;
			_files = _computer select 1;
			
			_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;
			_file = [_zfileName,[""]];
			_steed = _computer select 7;
			
			switch(true)do{
				case(_zfileName == ""):{													//No file name given
					_output = "Unspecified File Name";
				};
				case(str([_curDir,_zfileName] call File_fnc_getFile) == str(0)):{			//File name is not in current directory
					//Create skeleton file
					_file = [_zfileName,[""],_user];
					_steed = [_file select 0, _file select 1, _file select 2] call Steed_fnc_newSteed;
					_computer set[4,"EDITOR"];
				};
				case(_zfileName != "" && str([_curDir,_zfileName] call File_fnc_getFile) != str(0) && [[_curDir,_zfileName] call File_fnc_getFile] call File_fnc_getType):{	
					_output = "Specified file name is already a directory";					//File name is not in current directory
				};
				case(str([_curDir,_zfileName] call File_fnc_getFile) != str(0) && str([_curDir,_zfileName] call File_fnc_getFile select 2) != str("PUBLIC") && (str([_curDir,_zfileName] call File_fnc_getFile select 2) != str(_user))):{
																							//File name is already a file but user does not have permission
					_output = "You lack the required permission to view/edit this file";
				};
				case(str([_curDir,_zfileName] call File_fnc_getFile) != str(0)):{			//File name is already a file and user has permission
					//get file
					_file = [_curDir,_zfileName] call File_fnc_getFile;
					_steed = [_file select 0, _file select 1, _file select 2] call Steed_fnc_newSteed;
					_computer set[4,"EDITOR"];
				};
			};
			_computer set[7,_steed];
			_output;
			
		};
		case(str(_cmd)==str("HELPSTEED")):{
			_output =	"Simulated TExt EDitor(STEED) HELP<br/>"+
						"  About: Steed is Arma Terminal's built in text editor. It has basic functionality but should not be considered a full fleged text editor<br/>"+
						"  Commands:<br/>"+
						"    LEFT ARROW = Move the cursor left<br/>"+
						"    RIGHT ARROW = Move the cursor right<br/>"+
						"    CONTROL Z = Exit Steed (DOES NOT SAVE)<br/>"+
						"    CONTROL S = Save document (DOES NOT EXIT)<br/>"+
						"    HOME = returns the cursor to the beginning of the document<br/>"+
						"    END = brings the cursor to the end of the document<br/>"+
						"    BACKSPACE = Remove character behind cursor<br/>"+
						"    DELETE = Remove character in front of cursor<br/>"+
						"    PAGE UP = Scroll steed up<br/>"+
						"    PAGE DOWN = Scroll steed down<br/>"+
						"    CONTROL C = Copy entire document to clipboard, this allows you to paste into a full text editor such as Notepad or Microsoft Word<br/>"+
						"    CONTROL V = Pastes text in clipboard into the document (WARNING: THIS WILL OVERWRITE THE ENTIRE DOCUMENT, even if the text in the clipboard is shorter than the document)<br/>"+
						"  NOTE: No hints or warnings are displayed before saving or exiting, be careful not to loose your work or overwrite anything important.";
		};
		case(str(_cmd)==str("USERADD")):{
			_output = "";
			_cache = [true, "USERADD0", "Specify User Name (Specify nothing to terminate command) : "];
			_commandLine set[6,_cache];
			_output;
		};
		case(str(_cmd)==str("LOGIN")):{
			if(str(_user) == str("PUBLIC"))then{
				_output = "";
				_cache = [true, "LOGIN0", "Enter User Name : "];
				_commandLine set[6,_cache];
			}else{
				_output = "User already logged in, log out before you log on to another user"
			};
			_output;
		};
		case(str(_cmd)==str("LOGOUT")):{
			if(str(_user)!=str("PUBLIC"))then{
				_output = "User logged out, returned to MASTER directory";
				_user = "PUBLIC";
				_computer set [2, _user];
				_filePath = ["MASTER"];			//Prevents logging out and being in a forbidden directory
				_commandLine set[2, _filePath];
			}else{
				_output = "No user logged in";
			};
			_output;
		};
		case(str(_cmd)==str("FILEHIDE")):{
			_output = "";
			
			_commandLine = _computer select 5;
			_filePath = _commandLine select 2;
			_files = _computer select 1;
			
			_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;
			
			_filName = _params select 0;
			_perm = _params select 1;
			
			switch(true)do{
				case(str(_user) == str("PUBLIC")):{										//If not logged in
					_output = "You are not logged in";
				};
				case(str([_curDir,_filName] call File_fnc_getFile) == str(0)):{			//If no file name given
					_output = "Unspecified File Name";
				};
				case(count _params < 2):{												//If no new file name given
					_output = "No permission specified for the file";
				};
				case(str(([_curDir,_filName] call File_fnc_getFile) select 2) != str("PUBLIC") && str(([_curDir,_filName] call File_fnc_getFile) select 2) != str(_user)):{
																						//You do not have permission to remove the specified file
					_output = "You lack the required permission to rename the specified file";
				};
				case(!(str(_perm)==str("PUBLIC") || str(_perm)==str("PRIVATE"))):{		//Proper permission not specified
					_output = "Proper permission type not specified";
				};
				case(str([_curDir,_filName] call File_fnc_getFile) != str(0) && (str(_perm)==str("PUBLIC") || str(_perm)==str("PRIVATE"))):{
																						//File exists and permission specified properly
					_theFile = [_curDir,_filName] call File_fnc_getFile;
					if(str(_perm)==str("PUBLIC"))then{
						_theFile set[2, "PUBLIC"];
					}else{
						_theFile set[2, _user];
					};
					_output = "Permission changed to " + _perm;
				};
			};
			
			_output;
		};
	};
}else{
	_output = "Not a valid command";
	switch(true)do{
		case(str(_cache select 1) == str("RM")):{			//Cache has data and RM cached it			
			if(str(_cache select 4) == str(["Y"]))then{		//User input y for yes

				_commandLine = _computer select 5;
				_filePath = _commandLine select 2;
				_files = _computer select 1;

				_curDir = [_files, _filePath] call CommandLine_fnc_getCurrentDir;
				_rmFile = [_curDir,_cache select 3] call File_fnc_getFile;
				_index = [_curDir, _rmFile select 0] call File_fnc_getFileIndex;
				_contents = _curDir select 1;		//Get file contents and modify it
				_contents set[_index, ""];
				_contents = _contents - [""];
				_curDir set[1, _contents];			//Up date file structure through reference
				
				_output = "File deleted";
			};
			
			if(str(_cache select 4) == str(["N"]))then{		//User input N for no
				_output = "File not deleted";
			};
			
			_cache = [false];
			_commandLine set[6,_cache];
			_output;
		};
		case(str(_cache select 1)==str("USERADD0")):{
			if(str(_cache select 3)!=str([""]))then{
				_userName = [_cache select 3] call Line_fnc_inputToString;
				if(str(_userName)!=str("PUBLIC"))then{
					_b0ol = false;
					{
						if(str(_userName)==str(_x select 1))then{
							_b0ol = true;
						};
					}forEach _users;
					if(_b0ol)then{
						_output = "User name already in use.";
						_cache = [true, "USERADD0", "Specify another User Name (Specify nothing to terminate command) : "];
						_commandLine set[6,_cache];
					}else{
						
						_cache = [true, "USERADD1", "Specify User Password:",_userName];
						_commandLine set[6,_cache];
						_commandLine set[7, true];		//Set input to be stared out
						_output = "";
					};
				}else{
					_output = "User name cannot be 'PUBLIC'";
					_cache = [false];
					_commandLine set[6,_cache];
				};
			}else{
				_output = "Action cancelled";
				_cache = [false];
				_commandLine set[6,_cache];
			};
			_output;
		};
		case(str(_cache select 1)==str("USERADD1")):{
			_password = [_cache select 4] call Line_fnc_inputToString;
			_cache = [true, "USERADD2", "Confirm Password:", (_cache select 3), _password];
			_commandLine set[6,_cache];
			_output = "";
			_output;
		};
		case(str(_cache select 1)==str("USERADD2")):{
			_confPassword =	[_cache select 5] call Line_fnc_inputToString;
			if(str(_confPassword)==str(_cache select 4))then{
				//Passwords match
				_commandLine set[7, false];		//make input not stared out
				_users set [count _users, [_confPassword, (_cache select 3)]];
				_computer set [0, _users];
				
				_cache = [false];
				_commandLine set[6,_cache];
				
				_output = "User created";
			}else{
				//Passwords dont match
				_cache = [true, "USERADD1", "Specify User Password:", (_cache select 3)];
				_commandLine set[6,_cache];
				_commandLine set[7, true];		//Set input to be stared out
				_output = "Passwords do not match.";
			};
			_output;
		};
		case(str(_cache select 1)==str("LOGIN0")):{
			_userName = [_cache select 3] call Line_fnc_inputToString;
			_b0ol = false;
			{
				if(str(_userName)==str(_x select 1))then{
					_b0ol = true;
				};
			}forEach _users;
			if(_b0ol)then{
				_cache = [true, "LOGIN1", "Enter Password : ", _userName];
				_commandLine set[6,_cache];
				_commandLine set[7, true];		//Set input to be stared out
				_output = "";
			}else{
				_output = "Specified User Name does not exist";
				_cache = [false];
				_commandLine set[6,_cache];
			};
			_output;
		};
		case(str(_cache select 1)==str("LOGIN1")):{
			_password = [_cache select 4] call Line_fnc_inputToString;
			_userName = _cache select 3;
			_b0ol = false;
			{
				if(str(_userName)==str(_x select 1) && str(_password) == str(_x select 0))then{
					_b0ol = true;
				};
			}forEach _users;
			_output = "";
			if(_b0ol)then{
				_user = _userName
			}else{
				_output = "Password incorrect";
			};
			_cache = [false];
			_commandLine set[6,_cache];
			_commandLine set[7, false];
			_computer set [2, _user];
			_output;
		};
	};
	_output;
};

[_output,_computer];