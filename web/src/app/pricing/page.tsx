import { Pricing,FAQ } from '@/components/pricing';
import { PageHeading } from '@/components/ui';
export const metadata={title:'Membership Plans'};
export default function Page(){return <div className="container page-wrap"><PageHeading eyebrow="Choose your rhythm" title="Memberships.">Session packs that help you show up, build skill and keep moving.</PageHeading><Pricing/><FAQ/></div>;}
