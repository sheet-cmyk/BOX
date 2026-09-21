'use client';
import { useState } from 'react';
import { documentId, limit, orderBy, QueryConstraint, startAfter } from 'firebase/firestore';
import { useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { Button } from '../ui';
export function usePaged(name:string,field:string,filters:QueryConstraint[]=[],filterKey=''){
  const [pages,setPages]=useState<Array<[unknown,string]|null>>([null]);
  const [key,setKey]=useState(filterKey);
  if(key!==filterKey){setKey(filterKey);setPages([null]);}
  const cursor=pages.at(-1),direction=field==='fullName'?'asc':'desc';
  const constraints=[...filters,orderBy(field,direction),orderBy(documentId(),direction),...(cursor?[startAfter(...cursor)]:[]),limit(26)];
  const data=useRows(name,constraints,`${field}:${filterKey}:${JSON.stringify(cursor)}`);
  const rows=data.rows.slice(0,25);
  return {...data,rows,page:pages.length,hasNext:data.rows.length>25,next:()=>{const last=rows.at(-1);if(last)setPages([...pages,[last[field],last.id]]);},previous:()=>setPages(pages.slice(0,-1))};
}
export function Pagination({data}:{data:ReturnType<typeof usePaged>}){return <div className="pagination"><Button className="secondary small" disabled={data.page===1} onClick={data.previous}>Previous</Button><span>Page {data.page} · {data.rows.length} results</span><Button className="secondary small" disabled={!data.hasNext} onClick={data.next}>Next</Button></div>;}
export function Status({row}:{row:Row}){return <span className={`status ${row.status}`}>{row.status}</span>;}
