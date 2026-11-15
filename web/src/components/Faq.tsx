import { faqs } from '@/content/landing';

export function Faq() {
  return (
    <section id="faq" className="section container narrow">
      <div className="section-head">
        <h2>Pertanyaan yang Sering Diajukan</h2>
        <p className="muted">Jawaban singkat seputar instalasi, lisensi, dan keamanan.</p>
      </div>
      <div className="faq">
        {faqs.map((f) => (
          <details key={f.q} className="glass">
            <summary>{f.q}</summary>
            <p>{f.a}</p>
          </details>
        ))}
      </div>
    </section>
  );
}
