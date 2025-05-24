"use strict";var u=Object.defineProperty;var g=Object.getOwnPropertyDescriptor;var $=Object.getOwnPropertyNames;var p=Object.prototype.hasOwnProperty;var h=(e,s)=>{for(var c in s)u(e,c,{get:s[c],enumerable:!0})},w=(e,s,c,l)=>{if(s&&typeof s=="object"||typeof s=="function")for(let t of $(s))!p.call(e,t)&&t!==c&&u(e,t,{get:()=>s[t],enumerable:!(l=g(s,t))||l.enumerable});return e};var y=e=>w(u({},"__esModule",{value:!0}),e);var M={};h(M,{confirmation:()=>F,default:()=>A});module.exports=y(M);var f=require("child_process");async function A(e){return new Promise((s,c)=>{let l=r=>new Promise((m,d)=>{(0,f.exec)(r,{cwd:e.path},(n,o,a)=>{n?d(a.trim()||n.message):m(o.trim())})}),t=()=>{l(`git commit -m "${e.message.replace(/"/g,'\\"')}"`).then(r=>{s({success:!0,message:r,path:e.path})}).catch(r=>c(`Failed to commit: ${r}`))};e.stageAll?l("git add .").then(t).catch(r=>c(`Failed to stage changes: ${r}`)):t()})}var F=async e=>({message:`Do you want to create the following Git commit?

\u{1F4C4} Files to be committed:
${(await(async()=>new Promise(t=>{e.stageAll?(0,f.exec)("git status --porcelain",{cwd:e.path},(r,m)=>{let d=m.split(`
`).filter(n=>n.trim()).map(n=>{let o=n[0],a=n[1],i=n.slice(3).trim();if(o==="M"&&a==="M")return`\u26A1\uFE0F ${i} (partially staged)`;if(o!==" "&&o!=="?")switch(o){case"M":return`\u{1F4DD} ${i} (modified)`;case"A":return`\u2728 ${i} (added)`;case"D":return`\u{1F5D1}\uFE0F  ${i} (deleted)`;case"R":return`\u{1F4CB} ${i} (renamed)`;default:return`\u2022 ${i}`}else{if(a==="?")return`\u2753 ${i} (untracked)`;if(a!==" ")switch(a){case"M":return`\u{1F4DD} ${i} (modified)`;case"D":return`\u{1F5D1}\uFE0F  ${i} (deleted)`;default:return`\u2022 ${i}`}}return`\u2022 ${i}`});t(d)}):(0,f.exec)("git diff --cached --name-status",{cwd:e.path},(r,m)=>{let d=m.split(`
`).filter(Boolean).map(n=>{let[o,a]=n.split("	");switch(o.trim()){case"M":return`\u{1F4DD} ${a} (modified)`;case"A":return`\u2728 ${a} (added)`;case"D":return`\u{1F5D1}\uFE0F  ${a} (deleted)`;case"R":return`\u{1F4CB} ${a} (renamed)`;default:return`\u2022 ${a}`}});t(d)})}))()).map(t=>`  ${t}`).join(`
`)}

\u{1F4AC} Commit Message:
`+e.message.split(`
`).map(t=>`  ${t}`).join(`
`),info:[{name:"Repository",value:e.path}]});0&&(module.exports={confirmation});
