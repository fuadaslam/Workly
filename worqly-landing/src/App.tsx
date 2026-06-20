import { useState } from 'react'

const NAV_LINKS = [
  { label: 'Features', href: '#features' },
  { label: 'How it works', href: '#how-it-works' },
  { label: 'Pricing', href: '#pricing' },
]

const FEATURES = [
  {
    icon: '📋',
    title: 'Work Order Management',
    desc: 'Create, assign, and track service orders end-to-end. Real-time status updates keep every stakeholder in sync.',
  },
  {
    icon: '🏢',
    title: 'Multi-Branch Operations',
    desc: 'Manage unlimited offices from a single dashboard. Compare revenue, workload, and performance across your entire network.',
  },
  {
    icon: '📊',
    title: 'Live KPI Dashboard',
    desc: 'Instant visibility into orders, cash collected, completion rates, and high-priority cases — no refresh needed.',
  },
  {
    icon: '🕐',
    title: 'Attendance & Leaves',
    desc: 'Digital check-in/out, leave requests with approvals, and automated absence tracking — all in one place.',
  },
  {
    icon: '🤝',
    title: 'Enquiry Pipeline',
    desc: 'Capture leads, assign to staff, and convert enquiries to work orders with one tap. Never lose a prospect again.',
  },
  {
    icon: '📎',
    title: 'Document Attachments',
    desc: 'Attach photos and documents directly to tasks. Compressed uploads keep storage lean while preserving quality.',
  },
  {
    icon: '📈',
    title: 'Reports & Exports',
    desc: 'Generate detailed Excel reports on any date range. Share financials with clients or management in seconds.',
  },
  {
    icon: '🌐',
    title: 'Arabic & English',
    desc: 'Full RTL support for Arabic with seamless language switching — built for teams across the GCC.',
  },
]

const STEPS = [
  {
    step: '01',
    title: 'Create your organisation',
    desc: 'Sign up, set up your offices and services, and invite your team. Takes under five minutes.',
  },
  {
    step: '02',
    title: 'Assign orders to staff',
    desc: 'New service requests land in your dashboard. Assign to the right person, set priority, and track progress live.',
  },
  {
    step: '03',
    title: 'Clients get results',
    desc: 'Staff complete tasks, upload documents, collect payment. Every step is logged and reportable.',
  },
]

const PLANS = [
  {
    name: 'Starter',
    price: '149',
    period: 'SAR / mo',
    highlight: false,
    features: ['1 branch', 'Up to 10 staff', 'Work orders & enquiries', 'Basic reports', 'Email support'],
  },
  {
    name: 'Professional',
    price: '399',
    period: 'SAR / mo',
    highlight: true,
    features: ['5 branches', 'Unlimited staff', 'Full KPI dashboard', 'Advanced analytics', 'Attendance & leaves', 'Document storage', 'Priority support'],
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    period: '',
    highlight: false,
    features: ['Unlimited branches', 'Custom roles & permissions', 'API access', 'Dedicated account manager', 'SLA guarantee', 'On-site onboarding'],
  },
]

export default function App() {
  const [menuOpen, setMenuOpen] = useState(false)

  return (
    <div className="min-h-screen bg-white text-[#0D1B2A]">

      {/* ── Navbar ── */}
      <header className="fixed top-0 left-0 right-0 z-50 border-b border-slate-100 bg-white/90 backdrop-blur-md">
        <div className="mx-auto max-w-6xl px-6 h-16 flex items-center justify-between">
          {/* Logo */}
          <a href="#" className="flex items-center gap-2.5 font-bold text-lg tracking-tight">
            <div className="w-7 h-7 rounded-lg bg-[#4361EE] flex items-center justify-center">
              <span className="text-white text-xs font-black">W</span>
            </div>
            <span>Worqly</span>
            <span className="hidden sm:inline text-xs font-normal text-slate-400 ml-0.5">by xoviq Labs</span>
          </a>

          {/* Desktop nav */}
          <nav className="hidden md:flex items-center gap-8">
            {NAV_LINKS.map(l => (
              <a key={l.label} href={l.href}
                className="text-sm text-slate-600 hover:text-[#4361EE] transition-colors font-medium">
                {l.label}
              </a>
            ))}
          </nav>

          {/* CTA */}
          <div className="hidden md:flex items-center gap-3">
            <a href="https://worqly.web.app" target="_blank" rel="noreferrer"
              className="text-sm font-medium text-slate-600 hover:text-[#4361EE] transition-colors">
              Sign in
            </a>
            <a href="https://worqly.web.app" target="_blank" rel="noreferrer"
              className="px-4 py-2 rounded-lg bg-[#4361EE] text-white text-sm font-semibold hover:bg-[#3451d1] transition-colors shadow-sm">
              Get started free
            </a>
          </div>

          {/* Mobile hamburger */}
          <button className="md:hidden p-2 rounded-lg hover:bg-slate-100" onClick={() => setMenuOpen(o => !o)}>
            <div className="w-5 h-0.5 bg-slate-700 mb-1" />
            <div className="w-5 h-0.5 bg-slate-700 mb-1" />
            <div className="w-5 h-0.5 bg-slate-700" />
          </button>
        </div>

        {/* Mobile menu */}
        {menuOpen && (
          <div className="md:hidden border-t border-slate-100 bg-white px-6 py-4 flex flex-col gap-4">
            {NAV_LINKS.map(l => (
              <a key={l.label} href={l.href} onClick={() => setMenuOpen(false)}
                className="text-sm font-medium text-slate-700">{l.label}</a>
            ))}
            <a href="https://worqly.web.app" target="_blank" rel="noreferrer"
              className="mt-2 w-full text-center px-4 py-2.5 rounded-lg bg-[#4361EE] text-white text-sm font-semibold">
              Get started free
            </a>
          </div>
        )}
      </header>

      {/* ── Hero ── */}
      <section className="pt-32 pb-24 gradient-hero">
        <div className="mx-auto max-w-4xl px-6 text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-[#4361EE]/20 bg-[#4361EE]/5 text-[#4361EE] text-xs font-semibold mb-8">
            <span className="w-1.5 h-1.5 rounded-full bg-[#4361EE] animate-pulse" />
            Built for service businesses in the GCC
          </div>

          <h1 className="text-5xl sm:text-6xl font-black tracking-tight leading-[1.08] mb-6">
            Run your entire <br />
            <span className="gradient-text">service operation</span><br />
            from one place
          </h1>

          <p className="text-lg text-slate-500 max-w-2xl mx-auto mb-10 leading-relaxed">
            Worqly brings work orders, staff, attendance, enquiries, and reports together — so you stop juggling spreadsheets and start focusing on customers.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a href="https://worqly.web.app" target="_blank" rel="noreferrer"
              className="w-full sm:w-auto px-8 py-3.5 rounded-xl bg-[#4361EE] text-white font-bold text-base hover:bg-[#3451d1] transition-colors shadow-lg shadow-[#4361EE]/25">
              Start for free →
            </a>
            <a href="#features"
              className="w-full sm:w-auto px-8 py-3.5 rounded-xl border border-slate-200 text-slate-700 font-semibold text-base hover:border-[#4361EE]/40 hover:text-[#4361EE] transition-colors">
              See features
            </a>
          </div>

          <p className="mt-5 text-xs text-slate-400">No credit card required · Arabic & English · Works on mobile & web</p>
        </div>

        {/* Dashboard preview card */}
        <div className="mx-auto max-w-5xl px-6 mt-16">
          <div className="rounded-2xl border border-slate-200 shadow-2xl shadow-slate-200 overflow-hidden">
            <div className="gradient-brand px-6 py-4 flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-red-400/70" />
              <div className="w-3 h-3 rounded-full bg-yellow-400/70" />
              <div className="w-3 h-3 rounded-full bg-green-400/70" />
              <span className="ml-3 text-white/40 text-xs font-mono">worqly.web.app</span>
            </div>
            <div className="gradient-brand p-8">
              {/* Fake KPI grid */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
                {[
                  { label: 'Total Orders', value: '284', color: '#4361EE' },
                  { label: 'Completed (wk)', value: '31', color: '#10B981' },
                  { label: 'Cash Collected', value: '42K SAR', color: '#F59E0B' },
                  { label: 'High Priority', value: '7', color: '#EF4444' },
                ].map(k => (
                  <div key={k.label} className="rounded-xl bg-white/5 border border-white/10 p-4">
                    <div className="w-8 h-8 rounded-lg mb-3 flex items-center justify-center"
                      style={{ background: `${k.color}22` }}>
                      <div className="w-3 h-3 rounded-full" style={{ background: k.color }} />
                    </div>
                    <div className="text-xl font-black text-white">{k.value}</div>
                    <div className="text-xs text-white/50 uppercase tracking-wide mt-0.5">{k.label}</div>
                  </div>
                ))}
              </div>
              {/* Fake order list */}
              <div className="rounded-xl bg-white/5 border border-white/10 overflow-hidden">
                <div className="px-4 py-3 border-b border-white/10 flex items-center justify-between">
                  <span className="text-white/70 text-xs font-semibold uppercase tracking-wider">Recent Orders</span>
                  <span className="text-[#4361EE] text-xs font-semibold">View all</span>
                </div>
                {[
                  { client: 'Ahmed Al-Farsi', service: 'AC Maintenance', status: 'In Progress', priority: 'High' },
                  { client: 'Sara Mahmoud', service: 'Plumbing Repair', status: 'Pending', priority: 'Normal' },
                  { client: 'Khalid Trading Co.', service: 'Electrical Inspection', status: 'Completed', priority: 'Normal' },
                ].map((o, i) => (
                  <div key={i} className={`px-4 py-3 flex items-center justify-between ${i < 2 ? 'border-b border-white/5' : ''}`}>
                    <div>
                      <div className="text-white text-sm font-semibold">{o.client}</div>
                      <div className="text-white/40 text-xs">{o.service}</div>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                        o.status === 'Completed' ? 'bg-emerald-500/20 text-emerald-400' :
                        o.status === 'In Progress' ? 'bg-blue-500/20 text-blue-400' :
                        'bg-amber-500/20 text-amber-400'
                      }`}>{o.status}</span>
                      {o.priority === 'High' && (
                        <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-red-500/20 text-red-400">High</span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Social proof bar ── */}
      <section className="border-y border-slate-100 bg-slate-50/60 py-8">
        <div className="mx-auto max-w-4xl px-6">
          <div className="flex flex-wrap items-center justify-center gap-x-12 gap-y-4 text-center">
            {[
              { value: '500+', label: 'Work orders managed' },
              { value: '12+', label: 'Offices on the platform' },
              { value: '98%', label: 'Uptime SLA' },
              { value: 'GCC', label: 'Region coverage' },
            ].map(s => (
              <div key={s.label}>
                <div className="text-2xl font-black text-[#0D1B2A]">{s.value}</div>
                <div className="text-xs text-slate-500 mt-0.5">{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Features ── */}
      <section id="features" className="py-24">
        <div className="mx-auto max-w-6xl px-6">
          <div className="text-center mb-16">
            <div className="text-xs font-bold uppercase tracking-widest text-[#4361EE] mb-3">Everything you need</div>
            <h2 className="text-4xl font-black tracking-tight">
              Built for operations teams<br />that actually get things done
            </h2>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {FEATURES.map(f => (
              <div key={f.title}
                className="card-hover rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
                <div className="text-3xl mb-4">{f.icon}</div>
                <h3 className="font-bold text-[#0D1B2A] mb-2 text-sm">{f.title}</h3>
                <p className="text-slate-500 text-sm leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── How it works ── */}
      <section id="how-it-works" className="py-24 bg-slate-50/60">
        <div className="mx-auto max-w-5xl px-6">
          <div className="text-center mb-16">
            <div className="text-xs font-bold uppercase tracking-widest text-[#4361EE] mb-3">Simple by design</div>
            <h2 className="text-4xl font-black tracking-tight">Up and running in minutes</h2>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {STEPS.map((s, i) => (
              <div key={s.step} className="relative">
                {i < STEPS.length - 1 && (
                  <div className="hidden md:block absolute top-6 left-full w-full h-px border-t-2 border-dashed border-[#4361EE]/20 z-0" style={{ width: 'calc(100% - 3rem)', left: '3rem' }} />
                )}
                <div className="relative z-10">
                  <div className="w-12 h-12 rounded-2xl bg-[#4361EE]/10 border border-[#4361EE]/20 flex items-center justify-center mb-5">
                    <span className="text-[#4361EE] font-black text-sm">{s.step}</span>
                  </div>
                  <h3 className="font-bold text-lg mb-2">{s.title}</h3>
                  <p className="text-slate-500 text-sm leading-relaxed">{s.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Pricing ── */}
      <section id="pricing" className="py-24">
        <div className="mx-auto max-w-5xl px-6">
          <div className="text-center mb-16">
            <div className="text-xs font-bold uppercase tracking-widest text-[#4361EE] mb-3">Transparent pricing</div>
            <h2 className="text-4xl font-black tracking-tight">Start free, scale with confidence</h2>
            <p className="text-slate-500 mt-4 text-sm">All plans include a 14-day free trial. No credit card required.</p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {PLANS.map(p => (
              <div key={p.name}
                className={`rounded-2xl p-7 flex flex-col ${
                  p.highlight
                    ? 'gradient-brand text-white shadow-2xl shadow-[#4361EE]/30 scale-[1.02]'
                    : 'border border-slate-100 bg-white shadow-sm'
                }`}>
                {p.highlight && (
                  <div className="text-xs font-bold uppercase tracking-widest text-[#7B93FF] mb-4">Most popular</div>
                )}
                <div className={`text-lg font-bold mb-1 ${p.highlight ? 'text-white' : 'text-[#0D1B2A]'}`}>{p.name}</div>
                <div className="flex items-baseline gap-1 mb-6">
                  <span className={`text-4xl font-black ${p.highlight ? 'text-white' : 'text-[#0D1B2A]'}`}>{p.price}</span>
                  {p.period && <span className={`text-sm ${p.highlight ? 'text-white/60' : 'text-slate-400'}`}>{p.period}</span>}
                </div>
                <ul className="flex-1 space-y-3 mb-8">
                  {p.features.map(f => (
                    <li key={f} className="flex items-start gap-2.5 text-sm">
                      <svg className={`w-4 h-4 mt-0.5 shrink-0 ${p.highlight ? 'text-[#7B93FF]' : 'text-[#4361EE]'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                      <span className={p.highlight ? 'text-white/80' : 'text-slate-600'}>{f}</span>
                    </li>
                  ))}
                </ul>
                <a href="https://worqly.web.app" target="_blank" rel="noreferrer"
                  className={`w-full text-center py-3 rounded-xl font-bold text-sm transition-colors ${
                    p.highlight
                      ? 'bg-white text-[#4361EE] hover:bg-slate-100'
                      : 'border border-[#4361EE] text-[#4361EE] hover:bg-[#4361EE] hover:text-white'
                  }`}>
                  {p.name === 'Enterprise' ? 'Contact sales' : 'Get started free'}
                </a>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Final CTA ── */}
      <section className="py-24 gradient-brand">
        <div className="mx-auto max-w-3xl px-6 text-center">
          <h2 className="text-4xl font-black text-white tracking-tight mb-5">
            Ready to streamline your operations?
          </h2>
          <p className="text-white/60 text-lg mb-10">
            Join teams across the GCC using Worqly to manage every order, shift, and client — in one platform.
          </p>
          <a href="https://worqly.web.app" target="_blank" rel="noreferrer"
            className="inline-flex items-center gap-2 px-8 py-4 rounded-xl bg-[#4361EE] text-white font-bold text-base hover:bg-[#5473f5] transition-colors shadow-lg shadow-black/20">
            Launch the app →
          </a>
          <p className="mt-5 text-white/30 text-xs">No setup fees · Cancel anytime · GCC data residency</p>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="border-t border-slate-100 py-10">
        <div className="mx-auto max-w-6xl px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 font-bold text-sm">
            <div className="w-6 h-6 rounded-md bg-[#4361EE] flex items-center justify-center">
              <span className="text-white text-xs font-black">W</span>
            </div>
            <span>Worqly</span>
            <span className="text-slate-400 font-normal">by xoviq Labs</span>
          </div>
          <p className="text-slate-400 text-xs">© {new Date().getFullYear()} xoviq Labs. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <a href="mailto:hello@xoviq.com" className="text-xs text-slate-400 hover:text-[#4361EE] transition-colors">Contact</a>
            <a href="#" className="text-xs text-slate-400 hover:text-[#4361EE] transition-colors">Privacy</a>
            <a href="#" className="text-xs text-slate-400 hover:text-[#4361EE] transition-colors">Terms</a>
          </div>
        </div>
      </footer>

    </div>
  )
}
