'use client';
import { useEffect, useState } from 'react';
import { DateTime } from 'luxon';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Timestamp, orderBy, where } from 'firebase/firestore';
import { useRouter } from 'next/navigation';
import { call } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { asDate, dateLabel, timeLabel, zone, errorMessage } from '@/lib/utils';
import { useAuth } from './providers';
import { Button, Empty, Loading, Modal, Notice, ActionLink } from './ui';
export function Schedule({compact=false}:{compact?:boolean}) {
  const {user}=useAuth(),router=useRouter();
  const [day,setDay]=useState(DateTime.now().setZone(zone).startOf('day')),[publicRows,setPublicRows]=useState<Row[]>([]),[publicLoading,setPublicLoading]=useState(false),[error,setError]=useState(''),[selected,setSelected]=useState<Row|null>(null),[success,setSuccess]=useState(false);
  const start=day.startOf('week'),end=start.plus({weeks:1}),key=start.toISODate()!;
  const live=useRows(user?'schedule':null,[where('isCancelled','==',false),where('date','>=',Timestamp.fromMillis(start.toMillis())),where('date','<',Timestamp.fromMillis(end.toMillis())),orderBy('date')],`${user?.uid}:${key}`);
  const programs=useRows(user?'classes':null,[where('isActive','==',true)],user?.uid);
  useEffect(()=>{ if(user)return; let active=true;setPublicLoading(true);setError('');call<{sessions:Row[]}>('getPublicSchedule',{from:start.toUTC().toISO(),to:end.toUTC().toISO()}).then(r=>{if(active)setPublicRows(r.sessions);}).catch(e=>{if(active)setError(errorMessage(e));}).finally(()=>{if(active)setPublicLoading(false);});return()=>{active=false;};},[key,user]);
  const rows: Row[]=user?live.rows.map(s=>({...programs.rows.find(c=>c.id===s.classId),...s,spots:s.maxSpots-s.bookedSpots} as Row)):publicRows;
  const visible=rows.filter(s=>DateTime.fromJSDate(asDate(s.date)).setZone(zone).hasSame(day,'day'));
  return <div><div className="week-nav"><button className="icon-button" aria-label="Previous week" onClick={()=>setDay(day.minus({weeks:1}))}><ChevronLeft/></button><h3>{day.toFormat('LLLL yyyy')}</h3><button className="icon-button" aria-label="Next week" onClick={()=>setDay(day.plus({weeks:1}))}><ChevronRight/></button></div><div className="day-grid">{Array.from({length:7},(_,i)=>start.plus({days:i})).map(d=><button key={d.toISODate()} className={`day ${d.hasSame(day,'day')?'active':''}`} aria-pressed={d.hasSame(day,'day')} onClick={()=>setDay(d)}><span>{d.toFormat('ccc')}</span><strong>{d.day}</strong></button>)}</div><p className="muted" style={{fontSize:12}}>All times are Pacific · {day.toFormat('cccc, LLLL d')}</p>{success&&<Notice>Your booking is confirmed. See you at the gym.</Notice>}{(error||live.error)&&<Notice error>{error||live.error}</Notice>}{(user?live.loading:publicLoading)?<Loading/>:visible.length===0?<Empty>No classes scheduled for this day. Try another day.</Empty>:<div className="class-list">{visible.slice(0,compact?3:100).map(s=><article className="card class-row" key={s.id}><img className="class-thumb" src="/assets/images/photos/photo_kid_boxing.png" alt=""/><div><span className="class-time">{timeLabel(s.date)} – {timeLabel(s.endAt)}</span><h3>{s.className||'Boxing class'}</h3><span className="muted" style={{fontSize:12}}>{s.ageGroup}</span></div><span className="spots availability">{s.spots} spots available</span><Button className="small" disabled={s.spots<=0||asDate(s.date)<new Date()} onClick={()=>user?setSelected(s):router.push('/signin?next=/book')}>{s.spots<=0?'Full':'Book Class'}</Button></article>)}</div>}{selected&&<BookingDialog session={selected} onClose={()=>setSelected(null)} onSuccess={()=>{setSelected(null);setSuccess(true);}}/>}</div>;
}
function BookingDialog({session,onClose,onSuccess}:{session:Row;onClose:()=>void;onSuccess:()=>void}) {
  const {profile}=useAuth(),[busy,setBusy]=useState(false),[error,setError]=useState('');
  const credits=(profile?.sessionsRemaining??0)-(profile?.sessionsReserved??0);
  async function book(){setBusy(true);setError('');try{await call('createBooking',{scheduleId:session.id});onSuccess();}catch(e){setError(errorMessage(e));}finally{setBusy(false);}}
  return <Modal title="Book Class" onClose={onClose}><img src="/assets/images/photos/photo_kid_boxing.png" style={{width:'100%',height:180,objectFit:'cover',borderRadius:8}} alt="Boxing training"/><h3 style={{marginTop:20}}>{session.className}</h3><dl className="detail-grid"><div><dt>DATE</dt><dd>{dateLabel(session.date)}</dd></div><div><dt>TIME</dt><dd>{timeLabel(session.date)} PT</dd></div><div><dt>LOCATION</dt><dd>{session.address||'3200 Naglee Rd, Tracy, CA'}</dd></div><div><dt>AVAILABILITY</dt><dd>{session.spots} spots</dd></div></dl>{error&&<Notice error>{error}</Notice>}{credits>0?<Button busy={busy} onClick={book} style={{width:'100%'}}>Confirm Booking →</Button>:<><Notice>Choose a membership plan to add session credits.</Notice><ActionLink href="/pricing">Choose a plan</ActionLink></>}</Modal>;
}
