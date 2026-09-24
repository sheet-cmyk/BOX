import { programs } from '@/lib/programs';
import { ActionLink, PageHeading } from './ui';
import { Programs } from './public-pages';
export function AdditionalPrograms() { return <div className="program-grid" style={{marginTop:24}}>{programs.map((program, i) => <article className="card stack" id={program.id} key={program.id}><span className="eyebrow">Program {String(i+1).padStart(2,'0')}</span><h3>{program.name}</h3><p className="muted">{program.description}</p><ActionLink href={`/schedule?program=${program.id}`} secondary>View Available Sessions</ActionLink><a href="/contact">Ask the coach about this program →</a></article>)}</div>; }
export function ProgramsPage() { return <div className="container page-wrap"><PageHeading eyebrow="Our programs" title="Train with purpose.">Explore our existing junior and group sessions, plus five ways to build your training routine. Availability and suitability are confirmed by the gym.</PageHeading><Programs/><AdditionalPrograms/></div>; }
