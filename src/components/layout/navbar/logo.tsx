import Image from "next/image";

export const Logo = () => {
	return (
		<div className="flex items-center">
			<Image
				src="/primary-logo.png"
				alt="Sphere IT Logo"
				width={138}
				height={42}
				priority
				className="object-contain"
			/>
		</div>
	);
};
