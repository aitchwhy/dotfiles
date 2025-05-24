"use strict";var a=Object.defineProperty;var c=Object.getOwnPropertyDescriptor;var l=Object.getOwnPropertyNames;var f=Object.prototype.hasOwnProperty;var d=(o,t)=>{for(var n in t)a(o,n,{get:t[n],enumerable:!0})},m=(o,t,n,i)=>{if(t&&typeof t=="object"||typeof t=="function")for(let e of l(t))!f.call(o,e)&&e!==n&&a(o,e,{get:()=>t[e],enumerable:!(i=c(t,e))||i.enumerable});return o};var u=o=>m(a({},"__esModule",{value:!0}),o);var L={};d(L,{default:()=>w});module.exports=u(L);var r=require("@raycast/api");var s=require("node:child_process");async function p(o){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:n}=(0,s.spawnSync)("osascript",["-e",o]);return process.env.LC_ALL=t,n.toString()}var w=async()=>{let o=`
        if application "Finder" is not running then
            return "Not running"
        end if

        tell application "Finder"
            set pathList to (quoted form of POSIX path of (folder of the front window as alias))
        end tell
    `;o+=`
        set command to "open -a /Applications/Warp.app " & pathList
        do shell script command
    `;try{let t=await p(o);await(0,r.showToast)(r.Toast.Style.Success,"Done",t)}catch{await(0,r.showToast)(r.Toast.Style.Failure,"Something went wrong")}};
