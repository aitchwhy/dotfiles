"use strict";var h=Object.create;var i=Object.defineProperty;var u=Object.getOwnPropertyDescriptor;var f=Object.getOwnPropertyNames;var w=Object.getPrototypeOf,G=Object.prototype.hasOwnProperty;var v=(t,e)=>{for(var n in e)i(t,n,{get:e[n],enumerable:!0})},l=(t,e,n,s)=>{if(e&&typeof e=="object"||typeof e=="function")for(let o of f(e))!G.call(t,o)&&o!==n&&i(t,o,{get:()=>e[o],enumerable:!(s=u(e,o))||s.enumerable});return t};var x=(t,e,n)=>(n=t!=null?h(w(t)):{},l(e||!t||!t.__esModule?i(n,"default",{value:t,enumerable:!0}):n,t)),S=t=>l(i({},"__esModule",{value:!0}),t);var F={};v(F,{default:()=>y});module.exports=S(F);var a=x(require("node:process"),1),c=require("node:util"),r=require("node:child_process"),g=(0,c.promisify)(r.execFile);async function p(t,{humanReadableOutput:e=!0}={}){if(a.default.platform!=="darwin")throw new Error("macOS only");let n=e?[]:["-ss"],{stdout:s}=await g("osascript",["-e",t,n]);return s.trim()}var m=require("@raycast/api");var d=`
tell application "System Events"
    set isGhosttyRunning to exists (processes where name is "Ghostty")
  end tell

tell application "Ghostty"
  if not isGhosttyRunning then
    activate
  else
    -- If Ghostty is already running, activate Finder first then activate Ghostty and send Cmd+N to create new window
    tell application "Finder" to activate
    activate
    tell application "System Events"
      tell process "Ghostty"
        keystroke "n" using {command down}
      end tell
    end tell
  end if
end tell`;async function y(){await p(d),await(0,m.popToRoot)()}
