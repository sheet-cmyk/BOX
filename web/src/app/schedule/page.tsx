import { Schedule } from '@/components/schedule';
import { PageHeading } from '@/components/ui';
export const metadata={title:'Class Schedule'};
export default function Page(){return <div className="container page-wrap"><PageHeading eyebrow="Train with purpose" title="Class Schedule.">Live availability for Junior Boy Boxing training in Tracy.</PageHeading><Schedule/></div>;}
