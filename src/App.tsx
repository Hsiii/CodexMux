import type { JSX } from 'react';
import { ArrowUpRight, Layers3, Sparkles } from 'lucide-react';

const featureList = [
    'Bun with release-age gatekeeping',
    'Vite + React + TypeScript baseline',
    'React Query and Lucide ready to use',
];

export function App(): JSX.Element {
    return (
        <main className='app-shell'>
            <section className='hero-panel'>
                <div className='eyebrow'>
                    <Sparkles aria-hidden='true' size={16} />
                    Universal frontend environment
                </div>

                <div className='hero-copy'>
                    <p className='kicker'>Template</p>
                    <h1>Ship faster with a clean, reusable frontend base.</h1>
                    <p className='lede'>
                        This starter keeps editor behavior, formatting, linting,
                        and app structure aligned before feature work begins.
                    </p>
                </div>

                <div className='hero-actions'>
                    <a
                        className='primary-action'
                        href='https://vite.dev/guide/'
                        rel='noreferrer'
                        target='_blank'
                    >
                        Read Vite docs
                        <ArrowUpRight aria-hidden='true' size={16} />
                    </a>
                </div>
            </section>

            <section aria-label='Included tooling' className='feature-panel'>
                <div className='panel-heading'>
                    <Layers3 aria-hidden='true' size={18} />
                    Included baseline
                </div>

                <ul className='feature-list'>
                    {featureList.map((feature) => (
                        <li key={feature}>{feature}</li>
                    ))}
                </ul>
            </section>
        </main>
    );
}
