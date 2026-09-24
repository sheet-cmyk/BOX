'use client';
import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { onAuthStateChanged, User, signOut } from 'firebase/auth';
import { doc, onSnapshot } from 'firebase/firestore';
import { auth, db, call } from '@/lib/firebase';
import { Row } from '@/lib/types';
import { errorMessage } from '@/lib/utils';

const AuthContext = createContext<{user:User|null; profile:Row|null; loading:boolean; error:string; logout:()=>Promise<void>}>({user:null,profile:null,loading:true,error:'',logout:async()=>{await signOut(auth);}});
export function Providers({children}:{children:ReactNode}) {
  const [user,setUser] = useState<User|null>(null), [profile,setProfile] = useState<Row|null>(null), [loading,setLoading] = useState(true), [error,setError] = useState('');
  useEffect(() => {
    let generation = 0;
    const stop = onAuthStateChanged(auth, next => {
      const current = ++generation;
      setUser(next); setProfile(null); setError(''); setLoading(!!next);
      if (next) call('initializeProfile').catch(e => {
        if (current === generation) { setError(errorMessage(e)); setLoading(false); }
      });
    });
    return () => { generation++; stop(); };
  }, []);
  useEffect(() => { if (!user) return; return onSnapshot(doc(db,'users',user.uid), snap => { if (snap.exists()) { setProfile({id:snap.id,...snap.data()}); setLoading(false); } }, e=>{setError(errorMessage(e));setLoading(false);}); }, [user]);
  return <AuthContext.Provider value={{user,profile,loading,error,logout:()=>signOut(auth)}}>{children}</AuthContext.Provider>;
}
export const useAuth = () => useContext(AuthContext);
