"use strict";var i=Object.defineProperty;var l=Object.getOwnPropertyDescriptor;var p=Object.getOwnPropertyNames;var d=Object.prototype.hasOwnProperty;var w=(r,t)=>{for(var n in t)i(r,n,{get:t[n],enumerable:!0})},u=(r,t,n,s)=>{if(t&&typeof t=="object"||typeof t=="function")for(let o of p(t))!d.call(r,o)&&o!==n&&i(r,o,{get:()=>t[o],enumerable:!(s=l(t,o))||s.enumerable});return r};var f=r=>u(i({},"__esModule",{value:!0}),r);var h={};w(h,{default:()=>m});module.exports=f(h);var e=require("@raycast/api");var a=require("node:child_process");async function c(r){if(process.platform!=="darwin")throw new Error("macOS only");let t=process.env.LC_ALL;delete process.env.LC_ALL;let{stdout:n}=(0,a.spawnSync)("osascript",["-e",r]);return process.env.LC_ALL=t,n.toString()}var m=async()=>{let r=`
        if application "Finder" is not running then
            return "Finder is not running"
        end if

        tell application "Finder"
            try
                set currentFolderPath to POSIX path of (folder of the front window as alias)
            on error
                return "No Finder window open"
            end try
        end tell
    `;r+=`
        set command to "open -n -b 'com.github.wez.wezterm' --args start --cwd " & quoted form of currentFolderPath
        do shell script command
    `;try{let t=await c(r);t==="Finder is not running"||t==="No Finder window open"?await(0,e.showToast)(e.Toast.Style.Failure,t):await(0,e.showToast)(e.Toast.Style.Success,"Done",t)}catch{await(0,e.showToast)(e.Toast.Style.Failure,"Something went wrong")}};
