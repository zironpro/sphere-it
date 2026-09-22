import type { Route } from "next";
import Image from "next/image";
import Link from "next/link";

import {
	IconChevronRight,
	IconSocialFacebook,
	IconSocialInstagram,
	IconSocialLinkedin,
	IconSocialX,
	IconSocialYoutube,
} from "@/assets/icons";

import { FOOTER } from "@/data/constants";
import { getFooterGlobal } from "@/modules/global/footer";
import { listLegalPages } from "@/modules/legal-pages/actions/query";
import { Footer as FooterType } from "@/payload-types";
import { FooterNavLink } from "@/types/layout";

// Static copyright year to avoid re-computation
const currentYear = new Date().getFullYear();

export const Footer = async () => {
	const [data, legalPages] = await Promise.all([
		getFooterGlobal(),
		listLegalPages(),
	]);
	return (
		<footer
			aria-label="Site footer"
			className="relative bg-primary-950"
			id="footer"
			role="contentinfo"
		>
			<div className="bg-foreground/30 text-stone-200">
				<div className="container max-w-7xl py-8 md:py-16">
					<div className="grid grid-cols-1 gap-8 lg:grid-cols-[.5fr_1fr] lg:gap-12">
						<div className="flex max-w-md flex-col justify-between gap-3">
							<div className="space-y-4 md:space-y-6">
								<Link
									aria-label="Sphere IT Global - Home"
									className="-m-2 block w-fit rounded-md p-2"
									href="/"
									title="Go to homepage"
								>
									<Image
										src="/secondary-logo.png"
										alt="Sphere IT Global Logo"
										width={138}
										height={42}
										className="object-contain"
									/>
								</Link>
								<p className="mt-6 text-balance text-muted-background">
									{data.description}
								</p>
							</div>

							<ul
								aria-label="Social media links"
								className="flex items-center gap-2"
								role="list"
							>
								{data.socials?.map((social) => (
									<SocialLink key={social.id} social={social} />
								))}
							</ul>
						</div>

						{/* Navigation sections */}
						<div
							aria-label="Footer navigation"
							className="grid grid-cols-2 gap-4 lg:grid-cols-4"
							role="navigation"
						>
							{FOOTER.map((item) => (
								<FooterSection item={item} key={item.id} />
							))}

							<FooterSection
								item={{
									id: "locations",
									heading: "Locations",
									links:
										data.locations
											?.filter((loc) => loc.link)
											.map((loc) => ({
												id: loc.id ?? loc.location,
												href: loc.link as Route,
												label: loc.location,
											})) ?? [],
								}}
							/>
						</div>
					</div>
				</div>

				{/* Bottom section */}
				<div className="border-t py-6">
					<div className="container flex max-w-7xl flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
						<p className="text-muted text-sm">
							Copyright © {currentYear} Sphere IT Global. All rights reserved.
						</p>
						<div className="sr-only">
							<p>
								Website designed and developed by{" "}
								<Link href="https://zironpro.ae" target="_blank">
									ZironPro
								</Link>
							</p>
						</div>
						<nav aria-label="Legal and policy links">
							<ul className="flex flex-wrap items-center gap-4" role="list">
								{legalPages.map((page) => (
									<li key={page.id ?? page.slug}>
										<Link
											aria-label={`Read our ${page.title}`}
											className="rounded-sm p-2 text-muted text-sm transition-colors duration-300 hover:text-primary-300 focus:outline-none focus:ring-2 focus:ring-primary-300 focus:ring-offset-2 focus:ring-offset-foreground"
											href={`/legal/${page.slug}` as Route}
											title={`Read our ${page.title}`}
										>
											{page.title}
										</Link>
									</li>
								))}
							</ul>
						</nav>
					</div>
				</div>
			</div>
		</footer>
	);
};

// Memoized sub-components for better performance
const SOCIAL_ICONS = {
	facebook: IconSocialFacebook,
	instagram: IconSocialInstagram,
	linkedin: IconSocialLinkedin,
	youtube: IconSocialYoutube,
	x: IconSocialX,
} as const;

const SocialLink = ({
	social,
}: {
	social: NonNullable<FooterType["socials"]>[number];
}) => {
	const Icon = social.platform ? SOCIAL_ICONS[social.platform] : null;

	if (!Icon || !social.link) return null;

	return (
		<li>
			<Link
				aria-label={`Follow us on ${social.platform || "social media"}`}
				className="group flex size-10 items-center justify-center rounded-md border bg-stone-alpha-10 shadow-sm transition-colors hover:bg-stone-700 focus:outline-none focus:ring-2 focus:ring-primary-300 focus:ring-offset-2 focus:ring-offset-foreground"
				href={social.link as Route}
				rel="noreferrer noopener"
				target="_blank"
				title={`Follow us on ${social.platform || "social media"}`}
			>
				<Icon className="size-5 text-stone-300 transition-colors group-hover:text-primary-400" />
			</Link>
		</li>
	);
};

const FooterLink = ({ link }: { link: FooterNavLink }) => {
	const Icon = link.Icon;
	return (
		<li className="w-full">
			<Link
				aria-label={`Navigate to ${link.label}`}
				className="group inline-flex w-full items-center gap-3 rounded-sm px-1 py-1 font-medium transition-colors duration-300 hover:text-primary-300 focus:outline-none focus:ring-2 focus:ring-primary-300 focus:ring-offset-2 focus:ring-offset-foreground"
				href={link.href as Route}
				rel={link.href.includes("http") ? "noreferrer noopener" : undefined}
				target={link.href.includes("http") ? "_blank" : undefined}
				title={`Navigate to ${link.label}`}
			>
				{Icon && (
					<div className="flex size-7 shrink-0 rounded-md bg-stone-800 transition-colors duration-300 group-hover:bg-primary-300 group-focus:bg-primary-300">
						<Icon className="m-auto size-4.5 transition-colors duration-300 group-hover:text-primary-950 group-focus:text-primary-950" />
					</div>
				)}
				<span>{link.label}</span>
			</Link>
		</li>
	);
};

const FooterSection = ({ item }: { item: (typeof FOOTER)[0] }) => {
	return (
		<nav aria-labelledby={`footer-heading-${item.id}`}>
			<h3
				className="mb-4 font-mono! text-badge text-muted-background uppercase"
				id={`footer-heading-${item.id}`}
			>
				{item.href ? (
					<Link
						aria-label={`Visit ${item.heading} page`}
						className="flex items-center justify-between rounded-md p-2 transition-colors duration-300 hover:text-primary-300 focus:outline-none focus:ring-2 focus:ring-primary-300 focus:ring-offset-2 focus:ring-offset-foreground"
						href={item.href}
						title={`Visit ${item.heading} page`}
					>
						{item.heading}
						<IconChevronRight aria-hidden="true" className="size-3" />
					</Link>
				) : (
					item.heading
				)}
			</h3>
			<ul className="space-y-3" role="list">
				{item.links.map((link) => (
					<FooterLink key={link.id} link={link} />
				))}
			</ul>
		</nav>
	);
};
