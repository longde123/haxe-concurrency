/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/

package cad;

import cad.Thread;
import haxe.concurrency.ConcurrentIntHash;
import haxe.Json;
import sys.net.Host;
import sys.net.Socket;

/**
 * The Concurrent Application Debugger will start a daemon thread to listen on a port
 * and produce JSON output of what the system is currently doing. You need to compile
 * with the '-D cad' flag turned on.
 * 
 * @author Sam MacPherson
 */
class Debugger {
	
	#if cad
	var s:Socket;
	var prettyOutput:Bool;
	
	function new (host:Host, port:Int, prettyOutput:Bool) {
		this.prettyOutput = prettyOutput;
		s = new Socket();
		s.bind(host, port);
		s.listen(1);
	}
	
	function buildJSON ():String {
		var state = new Array<Dynamic>();
		var threads:ConcurrentIntHash<Thread> = Reflect.field(Thread, "THREADS");
		for (i in threads) {
			state.push( { name:i.name, state:Std.string(i.state) } );
		}
		return Json.stringify(state);
	}
	
	function buildHTML ():String {
		var state = "<html><head><title>Concurrent Application Debugger</title><style>table { width: 100%; text-align: left; border-spacing: 0px; } table td, table th { padding: 8px; vertical-align: top; border-top: 1px solid #ddd; } table thead tr th { border-bottom: 2px solid #ddd; border-top: none; } .wait, .sleep { color: gray; } .run { color: green; } .term { color: red; }</style></head><body><table><thead><tr><th>Name</th><th>State</th><th>Location</th></tr></thead><tbody>";
		var threads:ConcurrentIntHash<Thread> = Reflect.field(Thread, "THREADS");
		for (i in threads) {
			var location = "";
			var tstate = "";
			var cls = "";
			switch (i.state) {
				case Waiting(line):
					tstate = "Waiting";
					location = line;
					cls = "wait";
				case Sleeping:
					tstate = "Sleeping";
					cls = "sleep";
				case Running:
					tstate = "Running";
					cls = "run";
				case Terminated:
					tstate = "Terminated";
					cls = "term";
			}
			state += "<tr class='" + cls + "'><td>" + i.name + "</td><td>" + tstate + "</td><td>" + location + "</td></tr>";
		}
		return state + "</tbody></table></body></html>";
	}
	
	function run ():Void {
		while (true) {
			var sock = s.accept();
			var line:String = null;
			do {
				try {
					line = sock.input.readLine();
				} catch (e:Dynamic) {
					break;
				}
			} while (line != "");
			sock.write(prettyOutput ? buildHTML() : buildJSON());
			sock.close();
		}
	}
	#end
	
	/**
	 * Start listening on the given host:port combination. By default JSON will be output.
	 * 
	 * @param host The host to listen on.
	 * @param port The port to listen on.
	 * @param ?prettyOutput If true then a full HTML display will be made.
	 */
	public static function listen (host:Host, port:Int, ?prettyOutput:Bool = false):Void {
		#if cad
		var d = new Debugger(host, port, prettyOutput);
		var t = Thread.create(d.run);
		t.name = "cad-daemon";
		#end
	}
	
}