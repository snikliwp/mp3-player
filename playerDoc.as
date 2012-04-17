package  {
	
	import flash.display.MovieClip;

	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;

	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.IOErrorEvent;	// local filesystem errors and corrupted file handling
	import flash.events.HTTPStatusEvent;
	
	import flash.utils.Timer;
	
	import flash.display.LoaderInfo;
	
	import flash.net.URLRequest;		// Go get the xml file
	import flash.net.URLLoader;			// Load the xml file
	
	import flash.text.TextField;
	import flash.text.TextFormat;





	
	public class playerDoc extends MovieClip {
		
		private var songList:Array = ["the-bitch-song.mp3", "1985.mp3", "high-school-never-ends.mp3"];	//eventually this will be retrieved from an XML file
		private var songListXML:Array = new Array;	// this will be retrieved from an XML file
		private var path:String = './music/';
		private var currentTrack:Number = 0;
		private var position:Number = 0;
		private var numSong:Number = 0;
		private var isPlaying:Boolean = false;
		private var s:Sound;
		private var sc:SoundChannel;
		private var context:SoundLoaderContext = new SoundLoaderContext(4000);
		private var timmy:Timer = new Timer(100, 0);
		private var vol:Number = 0.4;
		
		private var playList_mc:MovieClip;								// new playlist
		private var listEntry_mc:MovieClip;								// new playlist
		private var playListXML:String = "playlist.xml";			// name of the xml file
		private var listXML:XML;									// array to store the xml data
		private	var req:URLRequest = new URLRequest();				// Set up to get the xml data 
		private	var xmlLoader:URLLoader = new URLLoader();			// Set up to get the images

		public static const CLICK:String = "click";




public function playerDoc() {
			trace('in function playerDoc: ');
			// constructor code
			req = new URLRequest(playListXML);	
			xmlLoader = new URLLoader();										// Set up to get the images
			xmlLoader.addEventListener(Event.COMPLETE, getData);				// Event Listener for successful Completion
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlError);		// Event Listener for some Sort of IO Error
			xmlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, error404);	// Event Listener for a specific IO error - file not found
			xmlLoader.load(req);												// go get the XML file

			playlist_btn.addEventListener(CLICK, playList); 
			play_btn.addEventListener(CLICK, playClick); 
			pause_btn.addEventListener(CLICK, pauseClick); 
			stop_btn.addEventListener(MouseEvent.CLICK, stopClick); 
			next_btn.addEventListener(MouseEvent.CLICK, nextClick); 
			prev_btn.addEventListener(MouseEvent.CLICK, prevClick); 
			prev_btn.addEventListener(MouseEvent.CLICK, prevClick); 

			volume_mc.addEventListener(MouseEvent.CLICK, setNewVolume);
			volume_mc.addEventListener(MouseEvent.MOUSE_DOWN, startVolumeTracking);
			volume_mc.addEventListener(MouseEvent.MOUSE_UP, stopVolumeTracking);
			volume_mc.mask_mc.scaleX = vol;

			timmy.addEventListener(TimerEvent.TIMER, updateInterface);
			seek_mc.load_fill_mc.scaleX = 0;
			seek_mc.play_fill_mc.scaleX = 0;
			seek_mc.handle_mc.x = 0;

			seek_mc.hit_mc.addEventListener(MouseEvent.CLICK, jumpTo);
			
		}// end function playerDoc
		
		
		public function jumpTo(ev:MouseEvent):void{
			trace('in function jumpTo: ');
			//move to a new point on the song's timeline and start playing from there
			//if( isPlaying ){
				//pause the song
				pause_btn.dispatchEvent( new MouseEvent("click") );		//this will have set the position variable that we need to overwrite
				
				var pct:Number = ev.localX / ev.currentTarget.width;
				//we will switch this to use the XML value instead of the s.length
				position = pct * s.length;
				
				//play from the new position
				play_btn.dispatchEvent( new MouseEvent("click") );		
			/*}else{
				var pct:Number = ev.localX / ev.currentTarget.width;
				//we will switch this to use the XML value instead of the s.length
				position = pct * s.length;
				//now move the handle to the new position
				
			}*/
		}// end function jumpTo
		
		public function playClick(ev:MouseEvent):void{
			trace('in function playClick: ');
			//play the song
			if(!isPlaying){
				isPlaying = true;
				play_btn.visible = false;
				pause_btn.visible = true;
				var req:URLRequest = new URLRequest(path + songListXML[currentTrack]);
				var trans:SoundTransform = new SoundTransform(vol, 0);
				s = new Sound(req, context);
				sc = s.play(position, 0, trans);
				
				s.addEventListener(ProgressEvent.PROGRESS, songLoading);
				sc.addEventListener(Event.SOUND_COMPLETE, songDone);
				
				timmy.start();
			}
		}// end function playClick
		
		public function songDone(ev:Event):void{
			trace('in function songDone: ');
			//move to the next song
			next_btn.dispatchEvent( new MouseEvent("click") );		
			// stopSongCommon();
		}// end function songDone
		
		public function songLoading(ev:ProgressEvent):void{
			trace('in function songLoading: ');
			//get the percentage and move the scaleX of the seek_mc.load_fill_mc a percentage of seek_mc.bg_mc.width
			var pct:Number = ev.bytesLoaded / ev.bytesTotal;
			if( pct < .98){
				//update the load fill bar
				seek_mc.load_fill_mc.scaleX = pct;
				//trace( pct );
			}else{
				//if the pct is 99 or greater then remove the listener and set the scaleX to 100%
				s.removeEventListener(ProgressEvent.PROGRESS, songLoading);
				seek_mc.load_fill_mc.scaleX = 1;
			}
		}// end function songLoading
		
		public function updateInterface(ev:TimerEvent):void{
			trace('in function updateInterface: ');
			if( isPlaying ){
				//update the seek bar
				//use the sc.position and (s.length OR the time from the XML) to calculate the percentage played
				var pct:Number = sc.position / s.length;
				//expand the scaleX of the play_fill_mc
				//move the x position of the handle_mc
				seek_mc.play_fill_mc.scaleX = pct;
				seek_mc.handle_mc.x = seek_mc.bg_mc.width * pct;
				
				seek_mc.handle_mc.scaleX = pct * 1.2 + .8;		//this is how the Rocket Grew along the seek bar
				seek_mc.handle_mc.scaleY = pct * 1.2 + .8;
				
				//update the time
				//s.length is the length of the song in milliseconds -> we need to convert this to minutes and seconds
				var totalSeconds:Number = Math.floor( s.length / 1000) ;	//we want even numbers with no decimal place
				var currentSeconds:Number = Math.floor( pct * totalSeconds );		//my current number of seconds into the song
				
				var currentMinutes:Number = Math.floor( currentSeconds / 60);
				var remainderSeconds:Number = Math.floor( currentSeconds % 60 );
				var strMinutes:String = currentMinutes.toString();
				var strSeconds:String = remainderSeconds.toString();
				if( strSeconds.length == 1){
					strSeconds = "0" + strSeconds;		//add the leading zero to the seconds
				}
				time_mc.time_txt.text = strMinutes + ":" + strSeconds;
				
				//COUNTDOWN TIME
				var countDownSeconds:Number = totalSeconds - currentSeconds;
				currentMinutes = Math.floor( countDownSeconds / 60);
				remainderSeconds = Math.floor( countDownSeconds % 60 );
				strMinutes = currentMinutes.toString();
				strSeconds = remainderSeconds.toString();
				if( strSeconds.length == 1){
					strSeconds = "0" + strSeconds;		//add the leading zero to the seconds
				}
				countdown_txt.text = strMinutes + ":" + strSeconds;
				
				
				//update any animations that you have
				var lp:Number = sc.leftPeak / vol;
				musician_mc.head_mc.rotation = lp * 60 - 30;
				var rp:Number = sc.rightPeak / vol;
				musician_mc.garrett_mc.y = musician_mc.head_mc.y - (rp * 20);
				musician_mc.x = pct * stage.stageWidth;
				
			}
		}// end function updateInterface
		
		public function pauseClick(ev:MouseEvent):void{
			trace('in function pauseClick: ');
			if(isPlaying){
				position = sc.position;
				stopSongCommon();
			}
		}// end function pauseClick
		
		public function prevClick(ev:MouseEvent):void{
			trace('in function prevClick: ');
			stop_btn.dispatchEvent(new MouseEvent("click"));
			currentTrack--;
			if(currentTrack < 0){
				currentTrack = songListXML.length - 1;
			}
			play_btn.dispatchEvent(new MouseEvent("click"));
		}// end function prevClick
		
		public function nextClick(ev:MouseEvent):void{
			trace('in function nextClick: ');
			stop_btn.dispatchEvent(new MouseEvent("click"));
			currentTrack++;
			if(currentTrack >= songListXML.length){
				currentTrack = 0;
			}
			play_btn.dispatchEvent(new MouseEvent("click"));

		}// end function nextClick
		
		public function stopClick(ev:MouseEvent):void{
			trace('in function stopClick: ');
			if(isPlaying){
				position = 0;
				stopSongCommon();
				//send the play fill bar and handle back to start
				seek_mc.play_fill_mc.scaleX = 0;
				seek_mc.handle_mc.x = 0;
			}
		}// end function stopClick
		
		public function stopSongCommon():void{
			trace('in function stopSongCommon: ');
			isPlaying = false;
			play_btn.visible = true;
			pause_btn.visible = false;
			sc.stop();
			timmy.stop();
			sc.removeEventListener(Event.SOUND_COMPLETE, songDone);
		}// end function stopSongCommon
		
		public function setNewVolume(ev:MouseEvent):void{
			trace('in function setNewVolume: ');
			//calculate the new volume percentage
			//create a new SoundTransform
			//pass it to the SoundChannel
			vol = ev.localX / volume_mc.width;
			//ev.localX tells me the distance in the X direction from the volume_mc registration point
			var st:SoundTransform = new SoundTransform(vol, 0);
			sc.soundTransform = st;
			//set the mask to match the new volume
			volume_mc.mask_mc.scaleX = vol;
		}// end function setNewVolume

		public function startVolumeTracking(ev:MouseEvent):void{
			trace('in function startVolumeTracking: ');
			volume_mc.addEventListener(MouseEvent.MOUSE_MOVE, setNewVolume);
		}// end function startVolumeTracking
		
		public function stopVolumeTracking(ev:MouseEvent):void{
			trace('in function stopVolumeTracking: ');
			volume_mc.removeEventListener(MouseEvent.MOUSE_MOVE, setNewVolume);
		}// end function stopVolumeTracking
		
		public function getData(ev):void{
			trace('in function getData: ');
			listXML = XML(ev.target.data);			// load the array with the data from the XML file
			numSong = listXML.song.length();		// number of level1 tags in the XML file
			trace('listXML: ', listXML);
			trace('numSong: ', numSong);
			
			for (var i:Number = 0; i <= numSong - 1; i++) {
				trace('listXML.song: ', listXML.song[i].file);
				
//				trace('listXML.song.file.text: ', listXML.song[i].file.text);
//				trace('listXML.song.file.text: ', listXML.song[i].file.text);
				songListXML[i] = listXML.song[i].file;
			}
			trace('songListXML: ', songListXML);

			
			
		play_btn.dispatchEvent( new MouseEvent("click") );		

		}// end function getData
		
		public function xmlError(ev):void{
			trace('in function xmlError: ');
		}// end function xmlError
		
		public function error404(ev):void{
			trace('in function error404: ');
		}// end function error404
		
		public function playList(ev:MouseEvent): void {
			trace('in function playlist: ');
			// make the playlist visible expanding from the top
			var c:playListHolder = new playListHolder;
			c.x = 0;
			c.y = 420;
			this.addChild(c);
			
			var ypos:Number = 405;
			var d:listEntry;
			for (var i:Number = 0; i <= numSong - 1; i++) {
				d = new listEntry;
				d.lineItem_txt.text = listXML.song[i].title;
				d.x = 0;
				d.y = ypos + 15;
				c.addChild(d);
			}

			
			// the xml is loaded in 
			
		}// end function playlist
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}// end class playerDoc
	
}// end package playerDoc
