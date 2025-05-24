"use strict";var s=Object.defineProperty;var p=Object.getOwnPropertyDescriptor;var c=Object.getOwnPropertyNames;var d=Object.prototype.hasOwnProperty;var f=(e,t)=>{for(var n in t)s(e,n,{get:t[n],enumerable:!0})},m=(e,t,n,r)=>{if(t&&typeof t=="object"||typeof t=="function")for(let i of c(t))!d.call(e,i)&&i!==n&&s(e,i,{get:()=>t[i],enumerable:!(r=p(t,i))||r.enumerable});return e};var w=e=>m(s({},"__esModule",{value:!0}),e);var u={};f(u,{default:()=>h});module.exports=w(u);var o=require("@raycast/api");var a=require("node:child_process");async function l(e){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:n}=(0,a.spawnSync)("osascript",["-e",e]);return process.env.LC_ALL=t,n.toString()}var h=async()=>{let e=`
        if application "Finder" is not running then
            return "Not running"
        end if

        tell application "Finder"
            set pathList to (quoted form of POSIX path of (folder of the front window as alias))
        end tell
    `;e+=`
        tell application "System Events"
            if not (exists (processes where name is "Terminal")) then
                do shell script "open -a Terminal " & pathList
            else
                tell application "Terminal"
                activate
                if (count of windows) is 0 then
                    do script ("cd " & pathList)
                else
                    tell application "System Events" to tell process "Terminal.app" to keystroke "t" using command down
                    delay 1
                    do script ("cd " & pathList) in first window
                end if
                end tell
            end if
        end tell
    `;try{let t=await l(e);await(0,o.showToast)(o.Toast.Style.Success,"Done",t)}catch{await(0,o.showToast)(o.Toast.Style.Failure,"Something went wrong")}};
