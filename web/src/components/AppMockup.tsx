/**
 * Pure-CSS landscape mock-up of the Nuvio app dashboard (no screenshots, no fake data).
 * Decorative only, so it is hidden from assistive tech.
 */
const nav = ['Home', 'Instances', 'Versions', 'Plus', 'Settings'];

export function AppMockup({ version }: { version?: string }) {
  return (
    <div className="mock glass" aria-hidden="true">
      <div className="mock-bar">
        <span className="dot" /><span className="dot" /><span className="dot" />
        <span className="mock-title">Nuvio Launcher{version ? ` · v${version}` : ''}</span>
        <span className="chip chip-warn">BETA</span>
      </div>
      <div className="mock-body">
        <div className="mock-side">
          {nav.map((n, i) => (
            <span key={n} className={i === 0 ? 'on' : undefined}>{n}</span>
          ))}
        </div>
        <div className="mock-main">
          <div className="mock-play">
            <div>
              <span className="chip">VANILLA</span>
              <strong>Minecraft 1.21</strong>
              <small>Siap dimainkan</small>
            </div>
            <span className="mock-play-btn">▶ PLAY</span>
          </div>
          <div className="mock-tiles">
            <div><small>JAVA</small><b>Auto</b></div>
            <div><small>RAM</small><b>2048 MB</b></div>
            <div><small>UNDUHAN</small><b>4 thread</b></div>
          </div>
        </div>
        <div className="mock-list">
          <small>INSTANCE</small>
          <div className="on"><b>Survival 1.21</b><span>Vanilla</span></div>
          <div><b>Kreatif</b><span>1.20.4</span></div>
          <div><b>Eksperimen</b><span>24w40a</span></div>
        </div>
      </div>
    </div>
  );
}
