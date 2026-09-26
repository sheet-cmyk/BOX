'use client';
import { useEffect, useState } from 'react';
import { collection, doc, onSnapshot, query, QueryConstraint } from 'firebase/firestore';
import { db } from './firebase';
import { Row } from './types';
import { errorMessage } from './utils';
export function useRows(name:string|null, constraints:QueryConstraint[] = [], key='') {
  const [rows,setRows] = useState<Row[]>([]), [loading,setLoading] = useState(true), [error,setError] = useState('');
  useEffect(()=>{ setRows([]);setError(''); if (!name) {setLoading(false);return;} setLoading(true); return onSnapshot(query(collection(db,name),...constraints), s=>{setRows(s.docs.map(d=>({id:d.id,...d.data()})));setLoading(false);},e=>{setError(errorMessage(e));setLoading(false);}); },[name,key]);
  return {rows,loading,error};
}
export function useDocument(path:string|null) {
  const [data,setData] = useState<Row|null>(null);
  useEffect(()=>{ setData(null); if (!path) return; return onSnapshot(doc(db,path),s=>setData(s.exists()?{id:s.id,...s.data()}:null),()=>setData(null)); },[path]);
  return data;
}
