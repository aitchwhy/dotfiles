"use strict";var p=Object.defineProperty;var g=Object.getOwnPropertyDescriptor;var h=Object.getOwnPropertyNames;var f=Object.prototype.hasOwnProperty;var w=(t,i)=>{for(var e in i)p(t,e,{get:i[e],enumerable:!0})},y=(t,i,e,n)=>{if(i&&typeof i=="object"||typeof i=="function")for(let r of h(i))!f.call(t,r)&&r!==e&&p(t,r,{get:()=>i[r],enumerable:!(n=g(i,r))||n.enumerable});return t};var l=t=>y(p({},"__esModule",{value:!0}),t);var m={};w(m,{default:()=>u});module.exports=l(m);var o=require("child_process");async function u(t){return new Promise((i,e)=>{if(t.path){(0,o.exec)("git rev-parse --git-dir",{cwd:t.path},(r,a)=>{if(r){e(`This directory ${t.path} is not a git repository. Initialize a new repository with 'git init' first, or provide a correct path to an existing git repository.`);return}i({path:t.path,gitDir:a.trim()})});return}(0,o.exec)(`osascript -e '
      tell application "Finder"
        if (count of windows) > 0 then
          get POSIX path of (target of front window as alias)
        end if
      end tell
    '`,(r,a)=>{let s=a.trim()||process.cwd();(0,o.exec)("git rev-parse --git-dir",{cwd:s},(c,d)=>{if(c){e(`This directory ${s} is not a git repository. Initialize a new repository with 'git init' first, or provide a correct path to an existing git repository.`);return}i({path:s,gitDir:d.trim()})})})})}
