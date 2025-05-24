"use strict";var o=Object.defineProperty;var c=Object.getOwnPropertyDescriptor;var p=Object.getOwnPropertyNames;var d=Object.prototype.hasOwnProperty;var f=(t,e)=>{for(var i in e)o(t,i,{get:e[i],enumerable:!0})},w=(t,e,i,r)=>{if(e&&typeof e=="object"||typeof e=="function")for(let s of p(e))!d.call(t,s)&&s!==i&&o(t,s,{get:()=>e[s],enumerable:!(r=c(e,s))||r.enumerable});return t};var h=t=>w(o({},"__esModule",{value:!0}),t);var u={};f(u,{default:()=>m});module.exports=h(u);var n=require("@raycast/api");var a=require("node:child_process");async function l(t){if(process.platform!=="darwin")throw new Error("macOS only");let e=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:i}=(0,a.spawnSync)("osascript",["-e",t]);return process.env.LC_ALL=e,i.toString()}var m=async()=>{let t=`
        if application "Finder" is not running then
            return "Not running"
        end if

        tell application "Finder"
            set pathList to (quoted form of POSIX path of (folder of the front window as alias))
        end tell
    `;t+=`
        tell application "System Events"
            -- some versions might identify as "iTerm2" instead of "iTerm"
            set isRunning to (exists (processes where name is "iTerm")) or (exists (processes where name is "iTerm2"))
        end tell

        tell application "iTerm"
            activate
            set hasNoWindows to ((count of windows) is 0)
            if isRunning and hasNoWindows then
                create window with default profile
            end if
            select first window

            tell the first window
            if isRunning and hasNoWindows is false then
                create tab with default profile
            end if
            tell current session to write text "clear; cd " & pathList
            end tell
        end tell
    `;try{let e=await l(t);await(0,n.showToast)(n.Toast.Style.Success,"Done",e)}catch{await(0,n.showToast)(n.Toast.Style.Failure,"Something went wrong")}};
