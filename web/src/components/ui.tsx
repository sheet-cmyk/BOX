'use client';
import { ButtonHTMLAttributes, ReactNode, useEffect, useRef } from 'react';
import { X, ArrowRight, LoaderCircle } from 'lucide-react';
import Link from 'next/link';
export function Button({children,busy,...props}:ButtonHTMLAttributes<HTMLButtonElement>&{busy?:boolean}) { return <button {...props} className={`button ${props.className||''}`} disabled={busy||props.disabled}>{busy?<LoaderCircle className="spin" size={18}/>:null}{children}</button>; }
export function ActionLink({href,children,secondary=false}:{href:string;children:ReactNode;secondary?:boolean}) { return <Link className={`button ${secondary?'secondary':''}`} href={href}>{children}<ArrowRight size={17}/></Link>; }
export function Notice({children,error=false}:{children:ReactNode;error?:boolean}) { return <div role={error?'alert':'status'} className={`notice ${error?'error':''}`}>{children}</div>; }
export function Loading() {return <div aria-label="Loading" className="loading"><LoaderCircle className="spin"/> Loading…</div>;}
export function Empty({children}:{children:ReactNode}) {return <div className="empty">{children}</div>;}
export function Modal({title,onClose,children}:{title:string;onClose:()=>void;children:ReactNode}) {
  const ref=useRef<HTMLDialogElement>(null);
  useEffect(()=>{ref.current?.showModal(); const prior=document.body.style.overflow;document.body.style.overflow='hidden';return()=>{document.body.style.overflow=prior;};},[]);
  return <dialog ref={ref} className="modal" onCancel={onClose} onClick={e=>{if(e.target===ref.current) onClose();}}><div className="modal-head"><h2>{title}</h2><button className="icon-button" aria-label="Close dialog" onClick={onClose}><X/></button></div>{children}</dialog>;
}
export function PageHeading({eyebrow,title,children}:{eyebrow?:string;title:string;children?:ReactNode}) {return <div className="page-heading">{eyebrow&&<p className="eyebrow">{eyebrow}</p>}<h1>{title}</h1>{children&&<p className="lede">{children}</p>}</div>;}
